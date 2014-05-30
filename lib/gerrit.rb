require 'httpi'
require 'json'
require 'base64'

class Gerrit < Struct.new(:base_url, :username, :password)

  def get endpoint
    puts "Gerrit get #{endpoint}" if Rails.env.development?
    req = HTTPI::Request.new File.join(base_url, username ? 'a' : '', endpoint)
    req.auth.digest username, password if username && password && !username.empty?
    req.auth.ssl.verify_mode = :none
    res = HTTPI.get req
    content_type = [*res.headers['Content-Type']].last.split(/[ ;]/).first
    case content_type
    when 'application/json'
      JSON.parse res.body.lines[1..-1].join
    when 'text/plain'
      case res.headers['X-FYI-Content-Encoding']
      when 'base64'
        Base64::decode64 res.body
      else
        res.body
      end
    else
      raise RuntimeError, "Unknown content type: #{content_type}"
    end
  end

end
