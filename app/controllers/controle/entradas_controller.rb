module Controle
  class EntradasController < BaseController
    before_action :exigir_ponto_acesso

    def new
    end

    def create
      validacao = ValidacaoEntrada.new(catraca: @ponto_acesso.catraca, identificacao: params[:matricula])

      if validacao.processar
        redirect_to controle_entrada_path, notice: validacao.mensagem, flash: { catraca: "liberada" }
      else
        flash.now[:alert] = validacao.mensagem
        render :new, status: :unprocessable_content
      end
    end

    private

    def exigir_ponto_acesso
      @ponto_acesso = Current.usuario.funcionario.ponto_acesso_atual
      return if @ponto_acesso

      redirect_to controle_ponto_acesso_path, alert: "Configure o ponto de acesso antes de operar a catraca"
    end
  end
end
