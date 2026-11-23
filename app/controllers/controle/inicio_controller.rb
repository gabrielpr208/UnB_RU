module Controle
  class InicioController < BaseController
    def show
      @funcionario = Current.usuario.funcionario
      @ponto_acesso = @funcionario.ponto_acesso_atual
    end
  end
end
