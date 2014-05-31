# == Schema Information
#
# Table name: hosts
#
#  id              :integer          not null, primary key
#  base_url        :string(255)      not null
#  allow_anonymous :boolean          default(FALSE), not null
#  is_local_net    :boolean          default(FALSE), not null
#

class Host < ActiveRecord::Base
  has_many :projects
  has_many :users

  def as_json
    {
      baseUrl: base_url
    }
  end
end
