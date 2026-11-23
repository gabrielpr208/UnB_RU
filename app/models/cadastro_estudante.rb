# Cadastro público do estudante, feito por ele mesmo com a matrícula (features/cadastro_estudante.feature).
class CadastroEstudante
  include CadastroDeUsuario

  attribute :matricula, :string

  private

  def nova_especializacao
    Estudante.new(usuario:, matricula:)
  end
end
