# == Schema Information
#
# Table name: change_comments
#
#  id              :integer          not null, primary key
#  author_id       :integer          not null
#  change_id       :integer          not null
#  local_id        :string(255)      not null
#  revision_number :integer
#  message         :text
#  created_at      :datetime
#  updated_at      :datetime
#

class ChangeComment < ActiveRecord::Base
  belongs_to :author, class_name: 'User'
  belongs_to :change
end
