# Formulário que grava um Usuario junto com a especialização dele (Estudante ou Funcionario, ver
# EspecializacaoDeUsuario): os dois são gravados juntos ou nenhum é, e os erros de ambos aparecem no formulário.
#
# Sem `editando`, cadastra um usuário novo. Com `editando` (uma especialização já gravada), altera os dados dela
# e do usuário dela; na edição, senha em branco mantém a senha atual.
#
# Quem inclui declara os atributos próprios do perfil e implementa #nova_especializacao (registro vazio)
# e #dados_da_especializacao (atributos do perfil vindos do formulário).
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

    # Especialização já gravada que o formulário altera; nil num cadastro novo.
    attr_accessor :editando

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

  # Na edição, trabalha numa cópia lida do banco: o registro recebido em `editando` não muda se a gravação falhar.
  def usuario
    @usuario ||= (editando ? Usuario.find(editando.usuario_id) : Usuario.new).tap do |usuario|
      usuario.assign_attributes(nome:, email:)
      if usuario.new_record? || senha.present? || confirmacao_senha.present?
        usuario.assign_attributes(senha:, senha_confirmation: confirmacao_senha)
      end
    end
  end

  def especializacao
    @especializacao ||= (editando ? editando.class.find(editando.id) : nova_especializacao).tap do |especializacao|
      especializacao.assign_attributes(usuario:, **dados_da_especializacao)
    end
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
