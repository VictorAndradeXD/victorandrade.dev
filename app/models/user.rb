require "argon2"

class User < ApplicationRecord
  # Argon2id no lugar do BCrypt do has_secure_password. m_cost é o log2 da
  # memória em KiB: 16 => 64 MiB. Custa ~230ms por hash aqui, o que é o ponto:
  # torna a força bruta cara mesmo com o digest em mãos.
  ARGON2_OPTIONS = { t_cost: 2, m_cost: 16, p_cost: 1 }.freeze

  MINIMUM_PASSWORD_LENGTH = 12
  MAX_FAILED_ATTEMPTS     = 10
  LOCKOUT_DURATION        = 15.minutes

  attr_reader :password
  attr_accessor :password_confirmation

  has_many :sessions, dependent: :destroy

  # Cada usuário tem a própria gestão financeira: nada é compartilhado.
  #
  # A ordem importa: o Rails destrói os dependentes na ordem de declaração, e
  # Account tem `restrict_with_error` enquanto sobrar lançamento. Com accounts
  # antes de transactions, apagar um usuário com histórico falharia calado.
  has_many :transactions,      dependent: :destroy
  has_many :installment_plans, dependent: :destroy
  has_many :recurring_rules,   dependent: :destroy
  has_many :accounts,          dependent: :destroy
  has_many :tags,              dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "não parece um e-mail válido" }
  validates :password_digest, presence: true
  validates :password, length: {
    minimum: MINIMUM_PASSWORD_LENGTH,
    message: "precisa ter pelo menos #{MINIMUM_PASSWORD_LENGTH} caracteres"
  }, if: -> { @password.present? }
  validate  :password_matches_confirmation

  # O token de reset morre junto com a senha antiga: trocar a senha invalida
  # qualquer link de recuperação que ainda esteja num e-mail por aí.
  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest&.last(10)
  end

  def password=(unencrypted)
    @password = unencrypted
    return if unencrypted.blank?

    self.password_digest = Argon2::Password.new(**ARGON2_OPTIONS).create(unencrypted)
  end

  # Autentica identificando o usuário e comparando a senha em tempo constante.
  # Aceita o hash de params que o SessionsController já monta.
  def self.authenticate_by(attributes)
    attributes = attributes.to_h.symbolize_keys
    password = attributes.delete(:password)
    raise ArgumentError, "password é obrigatório" if password.nil?

    if (user = find_by(attributes))
      user.authenticate(password)
    else
      # Gasta o mesmo tempo de um hash real. Sem isto, o tempo de resposta
      # denuncia quais e-mails existem no sistema.
      Argon2::Password.new(**ARGON2_OPTIONS).create(password)
      nil
    end
  end

  def authenticate(unencrypted)
    return nil if locked?

    if verify_password(unencrypted)
      register_success!
      self
    else
      register_failure!
      nil
    end
  end

  # O has_secure_password definia estes três por trás dos panos; o
  # PasswordsController e o PasswordsMailer dependem deles.
  def password_reset_token = generate_token_for(:password_reset)

  def self.find_by_password_reset_token(token)
    find_by_token_for(:password_reset, token)
  end

  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end

  def locked? = locked_until.present? && locked_until.future?

  def lock_remaining_minutes
    return 0 unless locked?

    ((locked_until - Time.current) / 60).ceil
  end

  def display_name = email_address.split("@").first.split(/[._-]/).first.capitalize

  private
    # Um digest que não seja Argon2 (um BCrypt antigo, um campo corrompido) faz
    # a lib levantar exceção. Isso é falha de autenticação, não erro 500.
    def verify_password(unencrypted)
      Argon2::Password.verify_password(unencrypted.to_s, password_digest)
    rescue Argon2::ArgonHashFail
      false
    end

    def register_success!
      update_columns(failed_attempts: 0, locked_until: nil, last_login_at: Time.current)
    end

    # Bloqueia a conta após tentativas seguidas. É o que segura um ataque que
    # troca de IP, onde o rate limit por IP não morde.
    def register_failure!
      attempts = failed_attempts + 1
      locked = attempts >= MAX_FAILED_ATTEMPTS

      update_columns(
        failed_attempts: locked ? 0 : attempts,
        locked_until: locked ? LOCKOUT_DURATION.from_now : locked_until
      )
    end

    def password_matches_confirmation
      return if @password.blank? || password_confirmation.nil?
      return if @password == password_confirmation

      errors.add(:password_confirmation, "não confere com a senha")
    end
end
