# == Schema Information
#
# Table name: revision_file_comments
#
#  id               :integer          not null, primary key
#  revision_file_id :integer
#  line             :integer
#  message          :text
#  author_id        :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class RevisionFileComment < ActiveRecord::Base
  belongs_to :revision_file
  belongs_to :author, class_name: 'User'
end
