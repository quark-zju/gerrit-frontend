# == Schema Information
#
# Table name: hosts
#
#  id       :integer          not null, primary key
#  base_url :string(255)      not null
#

class Host < ActiveRecord::Base
  has_many :projects
  has_many :users

  def as_json
    {
      base_url: base_url
    }
  end
end
