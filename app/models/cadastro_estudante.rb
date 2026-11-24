# Cadastro público do estudante, feito por ele mesmo com a matrícula (features/cadastro_estudante.feature).
class CadastroEstudante
  include CadastroDeUsuario

  attribute :matricula, :string

  private

  # Cria o Estudante, ainda vazio, que será gravado junto com o usuário.
  #
  # Argumentos:: nenhum.
  # Retorno:: um Estudante novo, ainda não gravado.
  # Efeitos colaterais:: nenhum.
  def nova_especializacao
    Estudante.new
  end

  # Atributos próprios do estudante vindos do formulário.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Hash+ com a +matricula+ digitada.
  # Efeitos colaterais:: nenhum.
  def dados_da_especializacao
    { matricula: }
  end
end
