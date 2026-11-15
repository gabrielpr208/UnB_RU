module Controle
  # Histórico de acessos de todos os restaurantes, com filtros e agrupamento (features/relatorio_global.feature),
  # e o Relatório Global de Operação em PDF (features/pdf_relatorio.feature).
  class RelatoriosController < BaseController
    somente_administradores

    def show
      @relatorio = RelatorioAcessos.new(params.permit(:restaurante_id, :catraca_id, :agrupar))
      @restaurantes = Restaurante.em_ordem
    end

    # Sempre o relatório completo: todos os acessos e todos os restaurantes, sem os filtros da tela.
    def pdf
      send_data RelatorioPdf.new.render,
                filename: "relatorio-global-#{Date.current.strftime('%Y-%m-%d')}.pdf",
                type: "application/pdf", disposition: "attachment"
    end

    private

    def mensagem_para_quem_nao_e_administrador
      action_name == "pdf" ? "Acesso restrito a administrador geral" : super
    end
  end
end
