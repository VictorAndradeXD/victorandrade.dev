require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:one) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email_address: @user.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "instruções foram enviadas"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "instruções foram enviadas"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "link de recuperação é inválido"
  end

  test "update" do
    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "senha-nova-valida", password_confirmation: "senha-nova-valida" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Senha alterada"
  end

  test "update with non matching passwords" do
    token = @user.password_reset_token
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "senha-longa-o-suficiente", password_confirmation: "outra-completamente" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "senhas não conferem"
  end

  test "update rejeita senha abaixo do mínimo" do
    token = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "curta", password_confirmation: "curta" }
      assert_redirected_to edit_password_path(token)
    end
  end

  private
    # Pelo id, não pela tag: o gerador assumia <div>, e o layout usa <p>.
    # Aceita notice e alert — algumas destas mensagens são de erro.
    def assert_notice(text)
      assert_select "#notice, #alert", /#{Regexp.escape(text)}/
    end
end
