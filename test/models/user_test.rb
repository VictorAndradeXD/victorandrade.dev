require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup { @user = users(:one) }

  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "a senha é guardada com Argon2id, nunca em texto" do
    @user.update!(password: "senha-bem-comprida", password_confirmation: "senha-bem-comprida")

    assert_match(/\A\$argon2id\$/, @user.password_digest)
    assert_not_includes @user.password_digest, "senha-bem-comprida"
  end

  test "autentica com a senha certa e recusa a errada" do
    assert_equal @user, User.authenticate_by(email_address: @user.email_address, password: "password")
    assert_nil User.authenticate_by(email_address: @user.email_address, password: "errada")
  end

  test "e-mail inexistente devolve nil sem explodir" do
    assert_nil User.authenticate_by(email_address: "ninguem@example.com", password: "password")
  end

  test "digest de outro algoritmo é falha de autenticação, não exceção" do
    @user.update_column(:password_digest, "$2a$12$umDigestBCryptAntigoQualquerCoisaAquiParaTeste")

    assert_nothing_raised do
      assert_nil User.authenticate_by(email_address: @user.email_address, password: "password")
    end
  end

  test "bloqueia a conta depois de tentativas seguidas" do
    User::MAX_FAILED_ATTEMPTS.times do
      User.authenticate_by(email_address: @user.email_address, password: "errada")
    end

    assert @user.reload.locked?
    assert_operator @user.lock_remaining_minutes, :>, 0
  end

  test "conta bloqueada recusa até a senha correta" do
    @user.update_columns(locked_until: 10.minutes.from_now)

    assert_nil User.authenticate_by(email_address: @user.email_address, password: "password")
  end

  test "acertar a senha zera o contador e registra o login" do
    @user.update_columns(failed_attempts: 3, locked_until: nil)

    User.authenticate_by(email_address: @user.email_address, password: "password")

    assert_equal 0, @user.reload.failed_attempts
    assert_not_nil @user.last_login_at
  end

  test "bloqueio expirado volta a aceitar" do
    @user.update_columns(locked_until: 1.minute.ago)

    assert_not @user.locked?
    assert_equal @user, User.authenticate_by(email_address: @user.email_address, password: "password")
  end

  test "senha precisa do mínimo de caracteres" do
    @user.password = "curta"
    assert_not @user.valid?

    @user.password = "a" * User::MINIMUM_PASSWORD_LENGTH
    assert @user.valid?
  end

  test "confirmação divergente é recusada" do
    @user.password = "senha-bem-comprida"
    @user.password_confirmation = "outra-bem-comprida"

    assert_not @user.valid?
    assert_includes @user.errors.attribute_names, :password_confirmation
  end

  test "e-mail é único e precisa ter forma de e-mail" do
    assert_not User.new(email_address: users(:two).email_address, password: "senha-bem-comprida").valid?
    assert_not User.new(email_address: "nao-e-email", password: "senha-bem-comprida").valid?
  end

  test "trocar a senha invalida o link de recuperação já emitido" do
    token = @user.password_reset_token
    assert_equal @user, User.find_by_password_reset_token!(token)

    @user.update!(password: "outra-senha-comprida", password_confirmation: "outra-senha-comprida")

    assert_raises(ActiveSupport::MessageVerifier::InvalidSignature) do
      User.find_by_password_reset_token!(token)
    end
  end

  test "apagar o usuário leva os dados financeiros junto" do
    account = @user.accounts.create!(name: "Conta", kind: "checking")
    @user.transactions.create!(kind: "expense", description: "x", amount: 10,
                               occurred_on: Date.current, account: account)

    assert_difference [ -> { Account.count }, -> { Transaction.count } ], -1 do
      @user.destroy
    end
  end
end
