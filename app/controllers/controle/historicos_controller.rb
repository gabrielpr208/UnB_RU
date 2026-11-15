module Controle
  class HistoricosController < BaseController
    before_action :exigir_ponto_acesso

    def index
      @catraca = @ponto_acesso.catraca
      @acessos = @catraca.acessos.mais_recentes.includes(:estudante)
    end

    private

    def exigir_ponto_acesso
      @ponto_acesso = Current.usuario.funcionario.ponto_acesso_atual
      return if @ponto_acesso

      redirect_to controle_ponto_acesso_path, alert: "Você deve ter uma catraca configurada para ver o histórico"
    end
  end
end
