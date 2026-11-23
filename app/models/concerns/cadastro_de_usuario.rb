# Formulário que cria um Usuario junto com a especialização dele (Estudante ou Funcionario, ver
# EspecializacaoDeUsuario): os dois são gravados juntos ou nenhum é, e os erros de ambos aparecem no formulário.
# Quem inclui declara os atributos próprios do perfil e implementa #nova_especializacao.
module CadastroDeUsuario
  extend ActiveSupport::Concern

  # Erros do Usuario que aparecem em outro campo do formulário.
  CAMPOS_DO_FORMULARIO = { senha_confirmation: :confirmacao_senha }.freeze

  included do
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :nome, :string
    attribute :email, :string
    attribute :senha, :string
    attribute :confirmacao_senha, :string

    validate :validar_modelos
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      usuario.save!
      especializacao.save!
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Outra requisição gravou o mesmo identificador ou e-mail depois da validação:
    # valida de novo, do zero, para mostrar no formulário qual campo ficou repetido.
    @usuario = @especializacao = nil
    valid?
    false
  end

  private

  def usuario
    @usuario ||= Usuario.new(nome:, email:, senha:, senha_confirmation: confirmacao_senha)
  end

  def especializacao
    @especializacao ||= nova_especializacao
  end

  def validar_modelos
    [ usuario, especializacao ].each do |modelo|
      next if modelo.valid?

      modelo.errors.each do |erro|
        errors.add(CAMPOS_DO_FORMULARIO.fetch(erro.attribute, erro.attribute), erro.message)
      end
    end
  end
end
