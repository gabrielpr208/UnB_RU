# Formulário que grava um Usuario junto com a especialização dele (Estudante ou Funcionario, ver
# EspecializacaoDeUsuario): os dois são gravados juntos ou nenhum é, e os erros de ambos aparecem no formulário.
#
# Sem +editando+, cadastra um usuário novo. Com +editando+ (uma especialização já gravada), altera os dados dela
# e do usuário dela; na edição, senha em branco mantém a senha atual.
#
# Quem inclui declara os atributos próprios do perfil e implementa +nova_especializacao+ (registro vazio)
# e +dados_da_especializacao+ (atributos do perfil vindos do formulário).
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

  # Valida o formulário e grava o usuário e a especialização numa mesma transação.
  #
  # Se outra requisição gravar o mesmo identificador ou e-mail depois da validação, o formulário é validado
  # de novo, do zero, para mostrar qual campo ficou repetido.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +true+ se os dois registros foram gravados;
  #   - +false+ se algum dado é inválido (os motivos ficam em +errors+).
  # Efeitos colaterais::
  #   cria ou altera o Usuario e o Estudante/Funcionario no banco. Em caso de falha, nada é gravado.
  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      usuario.save!
      especializacao.save!
    end
    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    @usuario = @especializacao = nil
    valid?
    false
  end

  private

  # Usuario que será gravado, já com os dados do formulário. Na edição, trabalha numa cópia lida do banco:
  # o registro recebido em +editando+ não muda se a gravação falhar.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Usuario (novo ou lido do banco), memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum no banco; na edição, faz uma consulta para ler o usuário.
  def usuario
    @usuario ||= (editando ? Usuario.find(editando.usuario_id) : Usuario.new).tap do |usuario|
      usuario.assign_attributes(nome:, email:)
      usuario.assign_attributes(senha:, senha_confirmation: confirmacao_senha) if alterar_senha?
    end
  end

  # Diz se a senha do usuário deve ser trocada: sempre num cadastro novo e, na edição, só se a senha ou a
  # confirmação foram preenchidas.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ ou +false+.
  # Efeitos colaterais:: nenhum.
  def alterar_senha?
    editando.nil? || senha.present? || confirmacao_senha.present?
  end

  # Especialização (Estudante ou Funcionario) que será gravada, já com os dados do formulário. Na edição,
  # também trabalha numa cópia lida do banco.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Estudante ou Funcionario (novo ou lido do banco), memorizado entre as chamadas.
  # Efeitos colaterais:: nenhum no banco; na edição, faz uma consulta para ler a especialização.
  def especializacao
    @especializacao ||= (editando ? editando.class.find(editando.id) : nova_especializacao).tap do |especializacao|
      especializacao.assign_attributes(usuario:, **dados_da_especializacao)
    end
  end

  # Validação que confere o Usuario e a especialização e traz os erros dos dois para o formulário.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   adiciona em +errors+ cada erro dos modelos, no campo correspondente do formulário
  #   (ver CAMPOS_DO_FORMULARIO).
  def validar_modelos
    [ usuario, especializacao ].each do |modelo|
      next if modelo.valid?

      modelo.errors.each do |erro|
        errors.add(CAMPOS_DO_FORMULARIO.fetch(erro.attribute, erro.attribute), erro.message)
      end
    end
  end
end
