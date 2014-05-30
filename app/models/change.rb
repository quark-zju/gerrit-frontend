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
#

class Change < ActiveRecord::Base
  belongs_to :host
  belongs_to :project
  belongs_to :owner, class_name: 'User'
  has_many :revisions
  has_many :change_comments

  alias :comments :change_comments

  class ChangeNotFound < RuntimeError; end

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
    host = Host.where(base_url: gerrit.base_url).first_or_create

    clause = where(options.merge(host_id: host.id)).includes(:revisions => :revision_files)
    change = clause.first || clause.create!(
      # not using first_or_create because it will calculate its params and won't work offline.
      begin
        change = gerrit.get "changes/#{options[:number] || options[:change_id]}/detail"
        raise ChangeNotFound unless change['kind']

        {
          owner_id: host.users.from_json(change['owner']).id,
          project_id: host.projects.where(name: change['project']).first_or_create.id,
          subject: change['subject'],
          branch: change['branch'],
          change_id: change['change_id'],
          number: change['_number'],
          created_at: DateTime.parse(change['created']),
          updated_at: DateTime.parse(change['updated']),
        }
      end
    )
    if options[:update] || change.revisions.empty?
      change.fetch_revisions gerrit
      change.fetch_comments gerrit
    end

    change
  rescue ChangeNotFound => ex
    nil
  end

  def fetch_revisions(gerrit)
    raise ArgumentError, 'base_url doesn\'t match' if gerrit.base_url != host.base_url
    revision_id = 1

    loop do
      revision = revisions.fetch(gerrit, number, revision_id)
      break unless revision
      revision_id += 1
    end
  end

  def fetch_comments(gerrit)
    raise ArgumentError, 'base_url doesn\'t match' if gerrit.base_url != host.base_url

    detail = gerrit.get "/changes/#{number}/detail"

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

  def as_json(deep = false)
    result = {
      branch: branch,
      changeId: change_id,
      createdAt: created_at,
      host: host.as_json,
      number: number,
      owner: owner.as_json,
      project: project.as_json,
      subject: subject,
      updatedAt: updated_at,
    }

    if deep
      result[:revisions] = revisions.map{|r|r.as_json(true)}
    end

    result
  end

end
