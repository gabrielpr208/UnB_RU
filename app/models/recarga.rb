# Recarga de créditos do estudante. É fictícia: nenhum PIX ou cartão de verdade é cobrado.
#
# - PIX: nasce pendente, com um código que vale por 1 minuto. O saldo só é creditado quando o
#   estudante confere o pagamento dentro desse prazo.
# - Cartão: nasce confirmada e o saldo é creditado na hora (ver PagamentoCartao).
class Recarga < ApplicationRecord
  VALOR_MINIMO = 1
  VALOR_MAXIMO = 1000
  VALIDADE_DO_PIX = 1.minute

  belongs_to :estudante

  attribute :valor, ValorMonetario.new

  enum :metodo, { pix: "pix", cartao: "cartao" }, validate: { message: "Forma de pagamento inválida" }
  enum :status, { pendente: "pendente", confirmada: "confirmada", expirada: "expirada" }, default: :pendente

  validate :validar_valor

  before_create :gerar_codigo_pix, if: :pix?

  def prazo_esgotado?(agora = Time.current)
    pix? && pendente? && expira_em <= agora
  end

  def segundos_restantes(agora = Time.current)
    [ (expira_em - agora).ceil, 0 ].max
  end

  # Simula a conferência do PIX junto ao banco: o pagamento é sempre aceito se o código ainda vale.
  # Credita o saldo uma única vez, mesmo que o estudante clique em "Conferir pagamento" mais de uma vez.
  def conferir_pagamento!
    with_lock do
      next unless pendente?

      if prazo_esgotado?
        expirada!
      else
        update!(status: :confirmada, confirmada_em: Time.current)
        estudante.creditar!(valor)
      end
    end
  end

  private

  def validar_valor
    if valor_before_type_cast.blank?
      errors.add(:valor, "Informe o valor da recarga")
    elsif valor.nil?
      errors.add(:valor, "Informe um valor numérico válido")
    elsif valor < VALOR_MINIMO
      errors.add(:valor, "O valor mínimo de recarga é #{ValorMonetario.formatar(VALOR_MINIMO)}")
    elsif valor > VALOR_MAXIMO
      errors.add(:valor, "O valor máximo de recarga é #{ValorMonetario.formatar(VALOR_MAXIMO)}")
    end
  end

  def gerar_codigo_pix
    self.expira_em = Time.current + VALIDADE_DO_PIX
    self.codigo_pix = CodigoPix.gerar(valor:)
  end
end
