module Controle
  # Página inicial da Aplicação de Controle.
  class InicioController < BaseController
    # Mostra a página inicial com o funcionário logado e o ponto de acesso em que ele está operando.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +show+.
    def show
      @funcionario = Current.usuario.funcionario
      @ponto_acesso = @funcionario.ponto_acesso_atual
    end
  end
end
