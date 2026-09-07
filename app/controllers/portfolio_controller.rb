class PortfolioController < ApplicationController
  include PublicLocale

  allow_unauthenticated_access
  layout "public"

  def show
  end
end
