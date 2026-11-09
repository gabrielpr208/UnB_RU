class CadastroEstudante
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :nome, :string
  attribute :matricula, :string
  attribute :email, :string
  attribute :senha, :string
  attribute :confirmacao_senha, :string

  CAMPOS_DO_FORMULARIO = { senha_confirmation: :confirmacao_senha }.freeze

  validate :validar_modelos

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      usuario.save!
      estudante.save!
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    @usuario = @estudante = nil
    valid?
    false
  end

  private

  def usuario
    @usuario ||= Usuario.new(nome:, email:, senha:, senha_confirmation: confirmacao_senha)
  end

  def estudante
    @estudante ||= Estudante.new(usuario:, matricula:)
  end

  def validar_modelos
    [ usuario, estudante ].each do |modelo|
      next if modelo.valid?

      modelo.errors.each do |erro|
        errors.add(CAMPOS_DO_FORMULARIO.fetch(erro.attribute, erro.attribute), erro.message)
      end
    end
  end
end
