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

  alias :files :revision_files

  class RevisionNotFound < RuntimeError; end

  def self.fetch(gerrit, change_id, revision_id)
    clause = where(local_id: revision_id)
    revision = clause.first || clause.create!(
      begin
        commit = gerrit.get "changes/#{change_id}/revisions/#{revision_id}/commit"
        raise RevisionNotFound unless commit['kind']

        user_to_s = lambda {|user| "#{user['name']} <#{user['email']}>"}

        {
          author: user_to_s[commit['author']],
          committer: user_to_s[commit['committer']],
          parent_commit: commit['parents'].map{|x|x['commit']}.join(' '),
          subject: commit['subject'],
          message: commit['message'],
        }
      end
    )

    revision.fetch_files(gerrit) if revision.files.empty?
    revision.fetch_comments(gerrit) if revision.comments.empty?

    revision
  rescue RevisionNotFound => ex
    nil
  end

  def fetch_files(gerrit)
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
      revision_files.where(pathname: pathname).first_or_create!(
        a: a.join("\n"),
        b: b.join("\n"),
      )
    end
  end

  def fetch_comments(gerrit)
    files_path_map = Hash[files.map{|f| [f.pathname, f]}]
    Hash[gerrit.get("changes/#{change.number}/revisions/#{local_id}/comments").map do |pathname, comments|
      file = files_path_map[pathname]
      raise RuntimeError, "Comment on a non-exist file: '#{pathname}'" unless file

      [pathname, comments.map do |comment|
        file.comments.where(:local_id => comment['id']).first_or_create!(
          author_id: change.host.users.from_json(comment['author']).id,
          line: comment['line'],
          message: comment['message'],
          created_at: DateTime.parse(comment['updated']),
        )
      end]
    end]
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
