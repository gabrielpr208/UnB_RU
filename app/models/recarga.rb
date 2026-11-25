# Recarga de créditos do estudante. É fictícia: nenhum PIX ou cartão de verdade é cobrado.
#
# - PIX: nasce pendente, com um código que vale por 1 minuto. O saldo só é creditado quando o
#   estudante confere o pagamento dentro desse prazo.
# - Cartão: nasce confirmada e o saldo é creditado na hora (ver PagamentoCartao).
class Recarga < ApplicationRecord
  # Menor valor aceito numa recarga, em reais.
  VALOR_MINIMO = 1
  # Maior valor aceito numa recarga, em reais.
  VALOR_MAXIMO = 1000
  # Tempo que o código PIX vale depois de gerado.
  VALIDADE_DO_PIX = 1.minute

  belongs_to :estudante

  attribute :valor, ValorMonetario.new

  enum :metodo, { pix: "pix", cartao: "cartao" }, validate: { message: "Forma de pagamento inválida" }
  enum :status, { pendente: "pendente", confirmada: "confirmada", expirada: "expirada" }, default: :pendente

  validate :validar_valor

  before_create :gerar_codigo_pix, if: :pix?

  # Diz se o código PIX de uma recarga pendente já venceu.
  #
  # Argumentos::
  #   - +agora+: horário de referência (padrão: +Time.current+).
  # Retorno::
  #   +true+ se a recarga é PIX, está pendente e o prazo acabou; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def prazo_esgotado?(agora = Time.current)
    pix? && pendente? && expira_em <= agora
  end

  # Tempo que falta para o código PIX vencer, mostrado no contador da tela.
  #
  # Argumentos::
  #   - +agora+: horário de referência (padrão: +Time.current+).
  # Retorno:: +Integer+ com os segundos restantes, arredondados para cima (+0+ se o prazo já acabou).
  # Efeitos colaterais:: nenhum.
  def segundos_restantes(agora = Time.current)
    [ (expira_em - agora).ceil, 0 ].max
  end

  # Simula a conferência do PIX junto ao banco: o pagamento é sempre aceito se o código ainda vale.
  # Credita o saldo uma única vez, mesmo que o estudante clique em "Conferir pagamento" mais de uma vez.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   nenhum valor relevante; o resultado fica no +status+ da recarga (+confirmada+ ou +expirada+).
  # Efeitos colaterais::
  #   com a recarga travada no banco: se o prazo acabou, marca a recarga como +expirada+; senão, marca como
  #   +confirmada+ e aumenta o saldo do estudante. Uma recarga que não está pendente não é alterada.
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

  # Validação do valor da recarga (ver #erro_do_valor).
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: adiciona um erro em +valor+ quando ele é inválido.
  def validar_valor
    mensagem = erro_do_valor
    errors.add(:valor, mensagem) if mensagem
  end

  # Confere o valor: precisa ser informado, numérico e estar entre VALOR_MINIMO e VALOR_MAXIMO.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +String+ com a mensagem de erro;
  #   - +nil+ se o valor é válido.
  # Efeitos colaterais:: nenhum.
  def erro_do_valor
    if valor_before_type_cast.blank?
      "Informe o valor da recarga"
    elsif valor.nil?
      "Informe um valor numérico válido"
    elsif valor < VALOR_MINIMO
      "O valor mínimo de recarga é #{ValorMonetario.formatar(VALOR_MINIMO)}"
    elsif valor > VALOR_MAXIMO
      "O valor máximo de recarga é #{ValorMonetario.formatar(VALOR_MAXIMO)}"
    end
  end

  # Callback que prepara uma recarga PIX antes de ela ser gravada pela primeira vez.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com o código PIX gerado (o valor não é usado pelo callback).
  # Efeitos colaterais::
  #   preenche +expira_em+ (agora + VALIDADE_DO_PIX) e +codigo_pix+ (ver CodigoPix.gerar), que são gravados
  #   junto com a recarga.
  def gerar_codigo_pix
    self.expira_em = Time.current + VALIDADE_DO_PIX
    self.codigo_pix = CodigoPix.gerar(valor:)
  end
end
