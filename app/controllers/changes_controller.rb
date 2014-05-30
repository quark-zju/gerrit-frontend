require 'gerrit'

class ChangesController < ApplicationController

  include PasswordsHelper

  before_filter :set_gerrit

  def show
    @change = Change.includes(:revisions => :revision_files).fetch(@gerrit, params[:change_id])
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
