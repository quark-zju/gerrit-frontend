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

  REQUIRED_FIELDS = %w[_account_id]

  def self.from_json(data)
    filled_fields = data.keys & REQUIRED_FIELDS
    raise ArgumentError, "data should have #{REQUIRED_FIELDS} set, but only #{filled_fields}" unless filled_fields.length == REQUIRED_FIELDS.length
    where(account_id: data['_account_id']).first_or_create!(
      email: data['email'] || '',
      name: data['name'] || data['username'] || data['_account_id'],
      username: data['username'] || data['_account_id'],
    )
  end

  def as_json
    {
      accountId: account_id,
      email: email,
      name: name,
      username: username,
    }
  end
end
