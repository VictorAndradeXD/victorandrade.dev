class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :locale_switchable?

  private
    def current_user = Current.user

    # Só o portfólio troca de idioma; o resto do site é em português. O
    # PublicLocale sobrescreve isto em quem de fato oferece a troca.
    def locale_switchable? = false
end
