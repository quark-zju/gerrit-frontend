require 'httpi'

class PagesController < ApplicationController
  include PasswordsHelper

  def passwords
    if request.post?
      update_passwords (params[:passwords] || {}).values
      render json: {result: 'success'}
    else
      @local_hosts = Host.where(:is_local_net => true)
    end
  end

end
