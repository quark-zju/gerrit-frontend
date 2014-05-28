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

  def self.fetch(gerrit, options)
    case options
    when Integer
      options = {number: options}
    when String
      options = {change_id: options}
    end

    if (options.keys & [:number, :change_id]).empty?
      raise ArgumentError, 'options should have either :number or :change_id set'
    end

    change = gerrit.get "changes/#{options[:number] || options[:change_id]}/detail"
    return nil unless change['kind']

    # Build project/host/owner on demand
    host = Host.where(base_url: gerrit.base_url).first_or_create
    project = host.projects.where(name: change['project']).first_or_create
    owner = host.users.from_json(change['owner'])

    where(options.merge(host_id: host.id, project_id: project.id)).first_or_create(
      owner: owner,
      subject: change['subject'],
      branch: change['branch'],
      change_id: change['change_id'],
      number: change['_number'],
      created_at: DateTime.parse(change['created']),
      updated_at: DateTime.parse(change['updated']),
    ).tap do |c|
        c.update_revisions gerrit
      end
  end

  def update_revisions(gerrit)
    raise ArgumentError, 'base_url doesn\'t match' if gerrit.base_url != host.base_url
    revision_id = 1

    loop do
      revision = revisions.fetch(gerrit, number, revision_id)
      break unless revision
      revision_id += 1
    end
  end

  def as_json(deep = false)
    result = {
      branch: branch,
      change_id: change_id,
      created_at: created_at,
      host: host.as_json,
      number: number,
      owner: owner.as_json,
      project: project.as_json,
      subject: subject,
      updated_at: updated_at,
    }

    if deep
      result[:revisions] = revisions.map{|r|r.as_json(true)}
    end

    result
  end

end
