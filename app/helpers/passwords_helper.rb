module PasswordsHelper

  def passwords
    @passwords ||= cookies.signed[:passwords] || []
  end

  def update_passwords new_passwords
    current_passwords = cookies.signed[:passwords]
    # remove deleted passwords
    current_passwords.reject! do |x|
      new_passwords.none? {|y| y['base_url'] == x['base_url']}
    end
    # merge new passwords
    new_passwords.each do |x|
      next unless x['password']
      current_passwords.reject! {|y| y['base_url'] == x['base_url']}
      current_passwords.push(
        base_url: x['base_url'].gsub(/\/$/, ''),
        username: x['username'],
        password: x['password'],
      )
    end
    cookies.permanent.signed[:passwords] = current_passwords
  end
end
