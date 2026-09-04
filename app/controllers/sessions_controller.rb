class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  # Primeira barreira: por IP. A segunda é o bloqueio por conta no User, que
  # continua valendo quando o atacante troca de endereço.
  rate_limit to: 5, within: 2.minutes, only: :create,
             with: -> { redirect_to new_session_path, alert: "Muitas tentativas. Aguarde alguns minutos." }

  def new
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password))

    if user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: failure_message
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    # Conta bloqueada ganha uma mensagem própria: sem ela o dono legítimo fica
    # tentando de novo sem entender por que a senha certa não passa. O custo é
    # confirmar que aquele e-mail existe — aceitável aqui, num sistema de dois
    # usuários, sem cadastro aberto e com os endereços já conhecidos.
    def failure_message
      user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

      if user&.locked?
        "Conta bloqueada por tentativas repetidas. Tente de novo em #{user.lock_remaining_minutes} min."
      else
        "E-mail ou senha incorretos."
      end
    end
end
