# == Schema Information
#
# Table name: revisions
#
#  id            :integer          not null, primary key
#  change_id     :integer          not null
#  local_id      :integer          not null
#  parent_commit :string(255)
#  author        :string(255)
#  committer     :string(255)
#  subject       :string(255)
#  message       :text
#

class Revision < ActiveRecord::Base
  belongs_to :change
  has_many :revision_files

  def self.fetch(gerrit, change_id, revision_id)
    # TODO: handle revision_id = 0
    commit = gerrit.get "changes/#{change_id}/revisions/#{revision_id}/commit"
    return nil unless commit['kind']

    user_to_s = lambda do |user|
      "#{user['name']} <#{user['email']}>"
    end

    where(local_id: revision_id).first_or_create(
      author: user_to_s[commit['author']],
      committer: user_to_s[commit['committer']],
      parent_commit: commit['parents'].map{|x|x['commit']}.join(' '),
      subject: commit['subject'],
      message: commit['message'],
    ).tap do |r|
        r.update_files(gerrit)
        r.update_comments(gerrit)
      end
  end

  def update_files(gerrit)
    pathnames = gerrit.get("changes/#{change.number}/revisions/#{local_id}/files").keys
    pathnames.each do |pathname|
      diff = gerrit.get("changes/#{change.number}/revisions/#{local_id}/files/#{pathname.gsub('/', '%2F')}/diff")
      a = []
      b = []
      diff['content'].each do |h| # DiffInfo
        h.each do |k, v|
          a += v if k.include?('a')
          b += v if k.include?('b')
        end
      end
      revision_files.where(pathname: pathname).first_or_create(
        a: a.join("\n"),
        b: b.join("\n"),
      )
    end
  end

  def update_comments(gerrit)
    comments = gerrit.get("changes/#{change.number}/revisions/#{local_id}/comments")
    # TODO
  end

  def files
    revision_files
  end

  def as_json(deep = false)
    result = {
      author: author,
      committer: committer,
      message: message,
      parentCommit: parent_commit,
      revisionId: local_id,
      subject: subject,
    }

    if deep
      result[:files] = Hash[revision_files.map{|r|[r.pathname, r.as_json]}]
    end

    result
  end
end
