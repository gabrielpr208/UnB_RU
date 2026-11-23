# Cadastro de funcionário pelo administrador, na Aplicação de Controle (features/cadastro_funcionario.feature).
# O administrador escolhe se o novo funcionário também será administrador; por padrão, não é.
class CadastroFuncionario
  include CadastroDeUsuario

  attribute :siape, :string
  attribute :administrador, :boolean, default: false

  private

  def nova_especializacao
    # Um valor vazio no formulário vira nil, mas a coluna não aceita nulo: sem escolha, não é administrador.
    Funcionario.new(usuario:, siape:, administrador: administrador || false)
  end
end
