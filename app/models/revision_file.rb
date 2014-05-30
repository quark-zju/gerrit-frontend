# == Schema Information
#
# Table name: revision_files
#
#  id          :integer          not null, primary key
#  revision_id :integer          not null
#  pathname    :string(255)      not null
#  a           :text
#  b           :text
#

class RevisionFile < ActiveRecord::Base
  belongs_to :revision
  has_many :revision_file_comments

  alias :comments :revision_file_comments

  def as_json
    {
      a: a,
      b: b,
      comments: comments.as_json,
      name: pathname,
    }
  end
end
