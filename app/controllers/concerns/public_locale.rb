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
      # A resposta passa a depender do Accept-Language de quem pediu. Sem o
      # Vary, um proxy ou CDN guardaria a versão em português e a serviria para
      # o próximo visitante, que pediu em inglês.
      response.headers["Vary"] = [ response.headers["Vary"], "Accept-Language" ].compact_blank.join(", ")

      I18n.with_locale(requested_locale, &)
    end

    # Nesta ordem: o que a pessoa acabou de clicar, o que ela escolheu numa
    # visita anterior, o idioma do navegador dela e, por fim, inglês. A escolha
    # explícita sempre ganha do palpite automático.
    def requested_locale
      if (chosen = supported_locale(params[:locale]))
        cookies.permanent[:locale] = chosen
        return chosen
      end

      supported_locale(cookies[:locale]) || browser_locale || "en"
    end

    def supported_locale(value)
      Portfolio::LOCALES.find { |locale| locale == value }
    end

    # Lê o "Accept-Language: pt-BR,pt;q=0.9,en-US;q=0.8" que o navegador manda.
    #
    # A comparação é só pela subtag primária, então pt-PT e pt-AO também caem no
    # pt-BR: ler em português de outro país é melhor do que cair no inglês. E a
    # ordem que vale é a do q=, não a da posição na lista.
    def browser_locale
      request.get_header("HTTP_ACCEPT_LANGUAGE").to_s.split(",").filter_map { |entry|
        tag, quality = entry.split(";q=")
        tag = tag.to_s.strip.downcase
        next if tag.empty? || tag == "*"

        [ tag.split("-").first, quality ? quality.to_f : 1.0 ]
      }.sort_by { |_, quality| -quality }
       .filter_map { |language, _| Portfolio::LOCALES.find { |l| l.split("-").first.downcase == language } }
       .first
    end
end
