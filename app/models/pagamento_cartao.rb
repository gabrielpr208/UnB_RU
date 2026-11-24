class PagamentoCartao
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Campos do cartão que precisam ser preenchidos.
  CAMPOS_DO_CARTAO = %i[ numero_cartao validade cvv ].freeze
  # Formato da validade: MM/AA ou MM/AAAA.
  VALIDADE = %r{\A(\d{2})/(\d{2}|\d{4})\z}

  attribute :valor, :string
  attribute :numero_cartao, :string
  attribute :validade, :string
  attribute :cvv, :string

  # Estudante que está fazendo a recarga.
  attr_accessor :estudante

  validate :validar_recarga
  validate :validar_cartao

  # Valida o formulário, grava a recarga como confirmada e credita o valor no saldo do estudante.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +true+ se a recarga foi confirmada;
  #   - +false+ se o valor ou os dados do cartão são inválidos (os motivos ficam em +errors+).
  # Efeitos colaterais::
  #   cria uma Recarga confirmada e aumenta o saldo do Estudante no banco, numa mesma transação.
  def save
    return false unless valid?

    Recarga.transaction do
      recarga.update!(status: :confirmada, confirmada_em: Time.current)
      estudante.creditar!(recarga.valor)
    end
    true
  end

  # Recarga via cartão montada com o valor do formulário.
  #
  # Argumentos:: nenhum.
  # Retorno:: a Recarga (gravada depois de #save), memorizada entre as chamadas.
  # Efeitos colaterais:: nenhum.
  def recarga
    @recarga ||= Recarga.new(estudante:, metodo: :cartao, valor:)
  end

  private

  # Validação do valor da recarga, com as mesmas regras de Recarga.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: copia para +errors+ os erros da Recarga.
  def validar_recarga
    return if recarga.valid?

    recarga.errors.each { |erro| errors.add(erro.attribute, erro.message) }
  end

  # Validação dos dados do cartão: todos os campos são obrigatórios e cada um tem o seu formato.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   adiciona um erro geral e um erro em cada campo em branco, além dos erros de formato
  #   (ver #validar_numero, #validar_validade e #validar_cvv).
  def validar_cartao
    validar_preenchimento
    validar_numero if numero_cartao.present?
    validar_validade if validade.present?
    validar_cvv if cvv.present?
  end

  # Confere se o número do cartão tem 16 dígitos (espaços são ignorados).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +numero_cartao+ quando o número é inválido.
  def validar_numero
    return if numero_cartao.gsub(/\s/, "").match?(/\A\d{16}\z/)

    errors.add(:numero_cartao, "Número do cartão inválido")
  end

  # Confere se o CVV tem 3 dígitos.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +cvv+ quando o código é inválido.
  def validar_cvv
    errors.add(:cvv, "CVV inválido") unless cvv.strip.match?(/\A\d{3}\z/)
  end

  # Confere o formato da validade e se o cartão ainda vale. O cartão vale até o último dia do mês da validade.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +validade+ quando o formato é inválido ou o cartão está vencido.
  def validar_validade
    fim = fim_da_validade

    if fim.nil?
      errors.add(:validade, "Validade inválida. Use o formato MM/AAAA")
    elsif fim < Date.current
      errors.add(:validade, "Cartão vencido")
    end
  end

  # Completa o ano da validade digitado com 2 dígitos.
  #
  # Argumentos::
  #   - +ano+: ano com 2 ou 4 dígitos.
  # Retorno:: +Integer+ com o ano de 4 dígitos (ex.: +30+ vira +2030+; +2030+ continua +2030+).
  # Efeitos colaterais:: nenhum.
  def ano_completo(ano)
    ano < 100 ? 2000 + ano : ano
  end
end
