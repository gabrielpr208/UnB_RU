module Controle
  # Histórico de acessos da catraca em que o funcionário está operando.
  class HistoricosController < BaseController
    before_action :exigir_ponto_acesso

    # Lista os acessos da catraca do ponto de acesso atual, do mais recente para o mais antigo.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +index+.
    def index
      @catraca = @ponto_acesso.catraca
      @acessos = @catraca.acessos.mais_recentes.includes(:estudante)
    end

    private

    # Filtro que exige um ponto de acesso configurado para ver o histórico.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   define <tt>@ponto_acesso</tt> com o ponto em aberto do funcionário; sem ponto, redireciona para a configuração
    #   do ponto de acesso com um alerta.
    def exigir_ponto_acesso
      @ponto_acesso = Current.usuario.funcionario.ponto_acesso_atual
      return if @ponto_acesso

      redirect_to controle_ponto_acesso_path, alert: "Você deve ter uma catraca configurada para ver o histórico"
    end
  end
end
