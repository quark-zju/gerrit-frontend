# == Schema Information
#
# Table name: changes
#
#  id         :integer          not null, primary key
#  host_id    :integer
#  change_id  :string(255)      not null
#  subject    :string(255)      not null
#  number     :integer          not null
#  project_id :integer
#  branch     :string(255)
#  owner_id   :integer
#  created_at :datetime
#  updated_at :datetime
#  status     :integer          default(0), not null
#

class Change < ActiveRecord::Base
  belongs_to :host
  belongs_to :project
  belongs_to :owner, class_name: 'User'
  has_many :revisions, :dependent => :destroy
  has_many :change_comments, :dependent => :delete_all

  alias :comments :change_comments

  class ChangeNotFound < RuntimeError; end

  STATUS_IDLE = 0
  STATUS_QUEUED = 1
  STATUS_FETCHING = 2

  def self.fetch(gerrit, options)
    case options
    when Integer, /\A[0-9]+\z/
      options = {number: options}
    when String
      options = {change_id: options}
    end

    if (options.keys & [:number, :change_id]).empty?
      raise ArgumentError, 'options should have either :number or :change_id set'
    end

    # Build project/host/owner on demand
    host = Host.where(base_url: gerrit.base_url).first_or_create!

    condition = options.reject{|k| k == :update}.merge(host_id: host.id)
    clause = where(condition).includes(
      {
        :change_comments => :author,
      },
      {
        :revisions => {
          :revision_files => [:a_content, :b_content, {:revision_file_comments => :author}],
        },
      },
    )
    change = clause.first || clause.create!(
      # not using first_or_create because it will calculate its params and won't work offline.
      begin
        change = gerrit.get "changes/#{options[:number] || options[:change_id]}/detail"
        raise ChangeNotFound unless change['kind']

        {
          owner_id: host.users.from_json(change['owner']).id,
          project_id: host.projects.where(name: change['project']).first_or_create!.id,
          subject: change['subject'],
          branch: change['branch'],
          change_id: change['change_id'],
          number: change['_number'],
          created_at: DateTime.parse(change['created']),
          updated_at: DateTime.parse(change['updated']),
        }
      end
    )

    update = options[:update]
    if update || (change.revisions.empty? && change.status == STATUS_IDLE)
      change.update_column :status, STATUS_QUEUED
      force_update_revision = update.to_i >= 2
      fetch_params = [gerrit, force_update_revision]
      if change.host.is_local_net
        change.fetch_dependencies(*fetch_params)
      else
        change.delay.fetch_dependencies(*fetch_params)
      end
    end

    change
  rescue ChangeNotFound => ex
    nil
  end

  def fetch_dependencies(gerrit, force_update_revision = false)
    return if status == STATUS_FETCHING
    update_column :status, STATUS_FETCHING
    begin
      fetch_comments gerrit
      fetch_revisions gerrit, force_update_revision
      touch
    ensure
      update_column :status, STATUS_IDLE
    end
  end

  def fetch_revisions(gerrit, force_update = false)
    raise ArgumentError, 'base_url doesn\'t match' if gerrit.base_url != host.base_url
    revision_id = 1

    loop do
      revision = revisions.fetch(gerrit, number, revision_id, force_update)
      break unless revision
      revision_id += 1
    end
  end

  def fetch_comments(gerrit)
    raise ArgumentError, 'base_url doesn\'t match' if gerrit.base_url != host.base_url

    detail = gerrit.get "/changes/#{number}/detail"

    ChangeComment.transaction do
      detail['messages'].map do |message|
        next unless message['id']
        comments.where(:local_id => message['id']).first_or_create!(
          author_id: host.users.from_json(message['author']).id,
          created_at: DateTime.parse(message['date']),
          local_id: message['id'],
          message: message['message'],
          revision_number: message['_revision_number'],
        )
      end
    end
  end

  STATUS_NOTES = {
    STATUS_FETCHING => 'Importing in progress. Current data is probably incomplete. Refresh at will.',
    STATUS_QUEUED => 'Scheduled for background importing. Current data is probably incomplete. Come back later.',
  }

  def as_json(deep = false)
    result = {
      branch: branch,
      changeId: change_id,
      createdAt: created_at,
      host: host.as_json,
      notice: STATUS_NOTES[status],
      number: number,
      owner: owner.as_json,
      project: project.as_json,
      subject: subject,
      updatedAt: updated_at,
    }

    if deep
      result[:revisions] = revisions.map{|r|r.as_json(true)}
      result[:comments] = comments.map{|c|c.as_json}
    end

    result
  end

end
