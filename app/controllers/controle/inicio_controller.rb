module Controle
  class InicioController < BaseController
    def show
      @funcionario = Current.usuario.funcionario
    end
  end
end
