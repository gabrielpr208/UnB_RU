# Página inicial do Portal do Estudante.
class InicioController < ApplicationController
  # Mostra a página inicial com os dados e o saldo do estudante logado.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +show+.
  def show
    @estudante = Current.usuario.estudante
  end
end
