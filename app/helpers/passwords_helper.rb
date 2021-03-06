module PasswordsHelper

  def passwords
    read_passwords
  end

  def host_in_passwords?(hostname)
    read_passwords.any? {|x| x['base_url'][/https?:\/\/([^\/]+)/i, 1].upcase == hostname.upcase}
  end

  def update_passwords new_passwords
    next_passwords = cookies.signed[:passwords] || []
    # remove deleted passwords
    next_passwords.reject! do |x|
      new_passwords.none? {|y| y['base_url'] == x['base_url']}
    end
    # merge new passwords
    new_passwords.each do |x|
      next if x['no_change']
      next_passwords.reject! {|y| y['base_url'] == x['base_url']}
      next_passwords.push(
        base_url: x['base_url'].gsub(/\/$/, ''),
        username: x['username'],
        password: x['password'],
      )
    end
    cookies.permanent.signed[:passwords] = next_passwords
  end

  private

    def read_passwords
      @passwords ||= cookies.signed[:passwords] || []
    end
end
