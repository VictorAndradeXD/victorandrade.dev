# Troca de idioma, hoje só do portfólio.
#
# Fica num concern, e não no ApplicationController, de propósito: o resto do
# site é em português. O Denfis, além disso, usa I18n para nomes de mês e
# formatos de data — se o idioma do portfólio vazasse para lá, alternar para
# inglês quebraria o calendário e o extrato.
module PublicLocale
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    # Liga o seletor de bandeiras no cabeçalho (ver ApplicationController).
    def locale_switchable? = true

    def switch_locale(&)
      I18n.with_locale(requested_locale, &)
    end

    # Prioridade: o que o visitante acabou de clicar, o que ele escolheu antes,
    # e por fim inglês — o alvo declarado do portfólio é vaga internacional.
    def requested_locale
      chosen = Portfolio::LOCALES.find { |l| l == params[:locale] }

      if chosen
        cookies.permanent[:locale] = chosen
        return chosen
      end

      Portfolio::LOCALES.find { |l| l == cookies[:locale] } || "en"
    end
end
