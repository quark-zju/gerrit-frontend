require 'httpi'

class PagesController < ApplicationController
  include PasswordsHelper

  def passwords
    if request.post?
      update_passwords (params[:passwords] || {}).values
    end
  end

end
