# Uma linha do extrato: uma recarga confirmada (entrada) ou uma refeição (saída).
#
# O valor tem sinal: positivo na recarga e negativo na refeição.
class Movimentacao < Data.define(:tipo, :valor, :data_hora, :detalhe)
  # Diz se a movimentação é uma recarga.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se o tipo é +:recarga+; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def recarga?
    tipo == :recarga
  end

  # Diz se a movimentação é uma refeição.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se o tipo é +:refeicao+; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def refeicao?
    tipo == :refeicao
  end
end
