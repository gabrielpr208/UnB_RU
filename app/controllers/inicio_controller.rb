class InicioController < ApplicationController
  def show
    @estudante = Current.usuario.estudante
  end
end
