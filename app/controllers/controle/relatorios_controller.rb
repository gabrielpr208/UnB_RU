module Controle
  # Histórico de acessos de todos os restaurantes, com filtros e agrupamento (features/relatorio_global.feature),
  # e o Relatório Global de Operação em PDF (features/pdf_relatorio.feature).
  class RelatoriosController < BaseController
    somente_administradores

    # Mostra o histórico de acessos com os filtros e o agrupamento escolhidos.
    #
    # Argumentos::
    #   nenhum; os filtros vêm de <tt>params[:restaurante_id]</tt>, <tt>params[:catraca_id]</tt> e
    #   <tt>params[:agrupar]</tt> (ver RelatorioAcessos).
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +show+.
    def show
      @relatorio = RelatorioAcessos.new(params.permit(:restaurante_id, :catraca_id, :agrupar))
      @restaurantes = Restaurante.em_ordem
    end

    # Baixa o Relatório Global de Operação em PDF. É sempre o relatório completo: todos os acessos e todos os
    # restaurantes, sem os filtros da tela.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   envia o arquivo <tt>relatorio-global-AAAA-MM-DD.pdf</tt> como download (ver RelatorioPdf).
    def pdf
      send_data RelatorioPdf.new.render,
                filename: "relatorio-global-#{Date.current.strftime('%Y-%m-%d')}.pdf",
                type: "application/pdf", disposition: "attachment"
    end

    private

    # Mensagem mostrada ao funcionário que não é administrador. O PDF tem uma mensagem própria.
    #
    # Argumentos:: nenhum.
    # Retorno::
    #   +String+: <tt>"Acesso restrito a administrador geral"</tt> na ação +pdf+; nas outras, a mensagem padrão de
    #   BaseController.
    # Efeitos colaterais:: nenhum.
    def mensagem_para_quem_nao_e_administrador
      action_name == "pdf" ? "Acesso restrito a administrador geral" : super
    end
  end
end
