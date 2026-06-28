class PagesController < ApplicationController
  allow_unauthenticated_access
  def index
    redirect_to events_path if authenticated?
  end
end
