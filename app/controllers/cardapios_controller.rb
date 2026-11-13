class CardapiosController < ApplicationController
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
