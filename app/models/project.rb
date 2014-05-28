# == Schema Information
#
# Table name: projects
#
#  id      :integer          not null, primary key
#  host_id :integer
#  name    :string(255)      not null
#

class Project < ActiveRecord::Base
  belongs_to :host

  def as_json
    {
      name: name,
    }
  end
end
