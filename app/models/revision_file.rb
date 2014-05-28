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

  def as_json
    {
      a: a,
      b: b,
      name: pathname,
    }
  end
end
