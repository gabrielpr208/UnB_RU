module Controle
  # Operação da catraca: o funcionário digita a matrícula do estudante e a entrada é liberada ou recusada.
  class EntradasController < BaseController
    before_action :exigir_ponto_acesso

    # Mostra o campo para digitar a matrícula do estudante.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
    end

    # Valida a entrada do estudante na catraca do ponto de acesso atual (ver ValidacaoEntrada).
    #
    # Argumentos:: nenhum; a matrícula vem de <tt>params[:matricula]</tt>.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   na entrada liberada, debita o saldo do estudante, registra o Acesso no banco e redireciona para a tela
    #   da catraca com a mensagem de sucesso; na recusa, renderiza a tela com o motivo (status 422).
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

    # Filtro que exige um ponto de acesso configurado para operar a catraca.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   define <tt>@ponto_acesso</tt> com o ponto em aberto do funcionário; sem ponto, redireciona para a configuração
    #   do ponto de acesso com um alerta.
    def exigir_ponto_acesso
      @ponto_acesso = Current.usuario.funcionario.ponto_acesso_atual
      return if @ponto_acesso

      redirect_to controle_ponto_acesso_path, alert: "Configure o ponto de acesso antes de operar a catraca"
    end
  end
end
