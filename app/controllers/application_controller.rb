class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :locale_switchable?

  private
    # Retoma a sessão antes de responder. Nas páginas públicas o
    # require_authentication é pulado, então ninguém chamou resume_session e o
    # Current.user estaria nil mesmo para quem está logado — foi assim que o
    # rodapé do portfólio deixou de oferecer os atalhos ao próprio dono. O
    # resume_session é memoizado e nem consulta o banco sem cookie, então
    # chamar aqui não custa nada para quem só está de passagem.
    def current_user
      resume_session
      Current.user
    end

    # Só o portfólio troca de idioma; o resto do site é em português. O
    # PublicLocale sobrescreve isto em quem de fato oferece a troca.
    def locale_switchable? = false

    # Para onde mandar alguém que acabou de entrar, ou que bateu numa porta que
    # não é dele: o módulo que ele de fato pode abrir.
    #
    # Quem não pode abrir nenhum cai no login em vez de num módulo — sem isso,
    # os guards abaixo redirecionariam em círculo. O check constraint na tabela
    # torna esse caso impossível, mas um laço infinito é caro demais para
    # depender só disso.
    def home_path_for(user)
      return new_session_path if user.nil?
      return denfis_root_path if user.denfis_access?
      return contabil_path    if user.accounting_access?

      new_session_path
    end

    def require_denfis_access
      return if current_user&.denfis_access?

      redirect_to home_path_for(current_user), alert: "Você não tem acesso ao Denfis."
    end

    def require_accounting_access
      return if current_user&.accounting_access?

      redirect_to home_path_for(current_user), alert: "Você não tem acesso ao módulo contábil."
    end
end
