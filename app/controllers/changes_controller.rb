require 'gerrit'

class ChangesController < ApplicationController

  include PasswordsHelper

  before_filter :set_gerrit

  def show
    options = {update: params[:update]}
    change_id = params[:change_id]
    case change_id
    when Integer, /\A[0-9]+\z/
      options.merge! number: change_id
    when String
      options.merge! change_id: change_id
    end

    @change = Change.fetch(@gerrit, options)
  end

  private

    def set_gerrit
      gerrit_hostname = params[:hostname]
      password = passwords.find {|x| x['base_url'][/https?:\/\/([^\/]+)/i, 1] == gerrit_hostname}
      unless password
        @gerrit_hostname = gerrit_hostname
        render 'missing_password'
        return false
      end
      @gerrit = Gerrit.new(*%w[base_url username password].map{|s| password[s]})
    end

end
