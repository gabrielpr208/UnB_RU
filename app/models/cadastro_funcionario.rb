# Cadastro e edição de funcionário pelo administrador, na Aplicação de Controle
# (features/cadastro_funcionario.feature e features/gerencia_funcionarios.feature).
# O administrador escolhe se o funcionário também será administrador; por padrão, não é.
class CadastroFuncionario
  include CadastroDeUsuario

  attribute :siape, :string
  attribute :administrador, :boolean, default: false

  # Funcionário logado que está fazendo a alteração.
  attr_accessor :responsavel

  # Ninguém tira o próprio acesso de administrador: assim sempre sobra ao menos um, o que está editando.
  validate :responsavel_continua_administrador

  # Formulário de edição, preenchido com os dados atuais do funcionário. A senha fica em branco.
  def self.editar(funcionario, responsavel:)
    new(editando: funcionario, responsavel:, nome: funcionario.nome, email: funcionario.email,
        siape: funcionario.siape, administrador: funcionario.administrador)
  end

  private

  def nova_especializacao
    Funcionario.new
  end

  def dados_da_especializacao
    # Um valor vazio no formulário vira nil, mas a coluna não aceita nulo: sem escolha, não é administrador.
    { siape:, administrador: administrador || false }
  end

  def responsavel_continua_administrador
    return if administrador || editando.nil? || editando != responsavel

    errors.add(:administrador, "Você não pode tirar o seu próprio acesso de administrador")
  end
end
