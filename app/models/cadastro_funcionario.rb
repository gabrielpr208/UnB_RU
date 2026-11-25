# Cadastro e edição de funcionário pelo administrador, na Aplicação de Controle
# (features/cadastro_funcionario.feature e features/gerencia_funcionarios.feature).
# O administrador escolhe se o funcionário também será administrador; por padrão, não é.
class CadastroFuncionario
  include CadastroDeUsuario

  attribute :siape, :string
  attribute :administrador, :boolean, default: false

  # Funcionário logado que está fazendo a alteração.
  attr_accessor :responsavel

  validate :responsavel_continua_administrador

  # Monta o formulário de edição, preenchido com os dados atuais do funcionário. A senha fica em branco.
  #
  # Argumentos::
  #   - +funcionario+: Funcionario que será editado.
  #   - +responsavel+: Funcionario logado que está fazendo a alteração.
  # Retorno:: um CadastroFuncionario no modo de edição.
  # Efeitos colaterais:: nenhum.
  def self.editar(funcionario, responsavel:)
    new(editando: funcionario, responsavel:, nome: funcionario.nome, email: funcionario.email,
        siape: funcionario.siape, administrador: funcionario.administrador)
  end

  private

  # Cria o Funcionario, ainda vazio, que será gravado junto com o usuário num cadastro novo.
  #
  # Argumentos:: nenhum.
  # Retorno:: um Funcionario novo, ainda não gravado.
  # Efeitos colaterais:: nenhum.
  def nova_especializacao
    Funcionario.new
  end

  # Atributos próprios do funcionário vindos do formulário. Um +administrador+ vazio no formulário vira +nil+,
  # mas a coluna não aceita nulo: sem escolha, o funcionário não é administrador.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Hash+ com o +siape+ e o +administrador+ (+true+ ou +false+).
  # Efeitos colaterais:: nenhum.
  def dados_da_especializacao
    { siape:, administrador: administrador || false }
  end

  # Validação que impede o funcionário logado de tirar o próprio acesso de administrador. Assim sempre sobra
  # ao menos um administrador: o que está editando.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   adiciona um erro em +administrador+ quando o responsável edita a si mesmo e desmarca a opção.
  def responsavel_continua_administrador
    return if administrador || editando.nil? || editando != responsavel

    errors.add(:administrador, "Você não pode tirar o seu próprio acesso de administrador")
  end
end
