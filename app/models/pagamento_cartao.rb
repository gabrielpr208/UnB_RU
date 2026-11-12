# Formulário da recarga via cartão de crédito. Os dados do cartão são fictícios: passam por uma
# conferência simples e não são guardados. Com dados válidos, o saldo é creditado na hora.
class PagamentoCartao
  include ActiveModel::Model
  include ActiveModel::Attributes

  CAMPOS_DO_CARTAO = %i[ numero_cartao validade cvv ].freeze
  VALIDADE = %r{\A(\d{2})/(\d{2}|\d{4})\z}

  attribute :valor, :string
  attribute :numero_cartao, :string
  attribute :validade, :string
  attribute :cvv, :string

  attr_accessor :estudante

  validate :validar_recarga
  validate :validar_cartao

  def save
    return false unless valid?

    Recarga.transaction do
      recarga.update!(status: :confirmada, confirmada_em: Time.current)
      estudante.creditar!(recarga.valor)
    end
    true
  end

  def recarga
    @recarga ||= Recarga.new(estudante:, metodo: :cartao, valor:)
  end

  private

  def validar_recarga
    return if recarga.valid?

    recarga.errors.each { |erro| errors.add(erro.attribute, erro.message) }
  end

  def validar_cartao
    em_branco = CAMPOS_DO_CARTAO.select { |campo| public_send(campo).blank? }
    errors.add(:base, "Preencha todos os dados do cartão") if em_branco.any?
    em_branco.each { |campo| errors.add(campo, "Campo obrigatório") }

    validar_numero if numero_cartao.present?
    validar_validade if validade.present?
    validar_cvv if cvv.present?
  end

  def validar_numero
    return if numero_cartao.gsub(/\s/, "").match?(/\A\d{16}\z/)

    errors.add(:numero_cartao, "Número do cartão inválido")
  end

  def validar_cvv
    errors.add(:cvv, "CVV inválido") unless cvv.strip.match?(/\A\d{3}\z/)
  end

  # O cartão vale até o último dia do mês da validade.
  def validar_validade
    mes, ano = validade.strip.match(VALIDADE)&.captures&.map(&:to_i)

    if mes.nil? || !(1..12).cover?(mes)
      errors.add(:validade, "Validade inválida. Use o formato MM/AAAA")
    elsif Date.new(ano < 100 ? 2000 + ano : ano, mes).end_of_month < Date.current
      errors.add(:validade, "Cartão vencido")
    end
  end
end
