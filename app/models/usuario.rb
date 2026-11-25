# Conta de acesso ao sistema, com nome, e-mail e senha. É especializada em Estudante ou Funcionario
# (ver EspecializacaoDeUsuario).
class Usuario < ApplicationRecord
  # Quantidade mínima de caracteres da senha.
  TAMANHO_MINIMO_SENHA = 6
  # Maior senha, em bytes, que o bcrypt consegue usar por inteiro.
  TAMANHO_MAXIMO_SENHA_BYTES = ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED

  has_secure_password :senha, validations: false, reset_token: false

  has_one :estudante, dependent: :destroy
  has_one :funcionario, dependent: :destroy
  has_many :sessoes, dependent: :destroy

  normalizes :nome, with: ->(nome) { nome.squish }
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :nome, presence: { message: "O nome é obrigatório" }

  validates :email, presence: { message: "O e-mail é obrigatório" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "Informe um e-mail válido" },
                    uniqueness: { message: "Este e-mail já está cadastrado" },
                    allow_blank: true

  validates :senha, presence: { message: "A senha é obrigatória" }, on: :create
  validates :senha, length: { minimum: TAMANHO_MINIMO_SENHA,
                              message: "A senha deve ter no mínimo #{TAMANHO_MINIMO_SENHA} caracteres" },
                    allow_blank: true
  validates :senha, confirmation: { message: "A confirmação de senha não confere" }
  validate :senha_dentro_do_limite_do_bcrypt

  private

  # Validação do tamanho máximo da senha: o bcrypt ignora o que passa de TAMANHO_MAXIMO_SENHA_BYTES.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +senha+ quando ela é longa demais.
  def senha_dentro_do_limite_do_bcrypt
    return if senha.blank? || senha.bytesize <= TAMANHO_MAXIMO_SENHA_BYTES

    errors.add(:senha, "A senha é longa demais")
  end
end
