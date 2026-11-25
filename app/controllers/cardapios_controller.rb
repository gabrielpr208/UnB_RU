# Cardápio da refeição servida agora, no Portal do Estudante.
class CardapiosController < ApplicationController
  # Mostra o cardápio da refeição em andamento ou, fora do horário, quando será a próxima refeição.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +show+.
  def show
    agora = Time.current
    @janela = HorarioDeRefeicao.em_andamento(agora)

    if @janela
      @cardapio = Cardapio.includes(:itens).find_by(data: agora.to_date, refeicao: @janela.refeicao)
    else
      @proxima = HorarioDeRefeicao.proxima(agora)
    end
  end
end
