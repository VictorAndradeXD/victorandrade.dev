class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 5, within: 2.minutes, only: :create,
             with: -> { redirect_to new_password_path, alert: "Muitas tentativas. Aguarde alguns minutos." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Se existir uma conta com esse e-mail, as instruções foram enviadas."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Senha alterada. Entre com a nova senha."
    else
      redirect_to edit_password_path(params[:token]), alert: "As senhas não conferem, ou a senha é curta demais (mínimo #{User::MINIMUM_PASSWORD_LENGTH} caracteres)."
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "O link de recuperação é inválido ou expirou."
    end
end
