# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  host_id    :integer          not null
#  name       :string(255)      not null
#  username   :string(255)      not null
#  email      :string(255)      not null
#  account_id :integer          not null
#

class User < ActiveRecord::Base
  belongs_to :host

  def self.from_json(data)
    raise ArgumentError, 'data should have _account_id, email, name, username set' unless (data.keys & %w[_account_id email name username]).length == 4
    where(account_id: data['_account_id']).first_or_create!(
      email: data['email'],
      name: data['name'],
      username: data['username'],
    )
  end

  def as_json
    {
      name: name,
      username: username,
      email: email,
    }
  end
end
