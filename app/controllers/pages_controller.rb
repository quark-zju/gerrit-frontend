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

  def root
    @sample_links = []
    Host.first(5).each do |host|
      if host.allow_anonymous || host_in_passwords?(host.hostname)
        change_number = Change.where(:host_id => host.id).first.try(:number) || 1
        @sample_links << "/#{host.hostname}/#{change_number}"
      end
    end
  end

end
