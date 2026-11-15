module Controle
  # Histórico de acessos de todos os restaurantes, com filtros e agrupamento (features/relatorio_global.feature).
  class RelatoriosController < BaseController
    somente_administradores

    def show
      @relatorio = RelatorioAcessos.new(params.permit(:restaurante_id, :catraca_id, :agrupar))
      @restaurantes = Restaurante.em_ordem
    end
  end
end
