# Uma linha do extrato: uma recarga confirmada (entrada) ou uma refeição (saída).
#
# O valor tem sinal: positivo na recarga e negativo na refeição.
Movimentacao = Data.define(:tipo, :valor, :data_hora, :detalhe) do
  def recarga?
    tipo == :recarga
  end

  def refeicao?
    tipo == :refeicao
  end
end
