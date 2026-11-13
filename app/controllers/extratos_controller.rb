class ExtratosController < ApplicationController
  def show
    @estudante = Current.usuario.estudante
    @extrato = Extrato.new(params.permit(:tipo, :data_inicial, :data_final, :valor_minimo, :valor_maximo))
    @extrato.estudante = @estudante

    render :show, status: :unprocessable_content if @extrato.invalid?
  end

  private

  def mensagem_para_pedir_login
    "Você deve estar logado para ver o extrato"
  end
end
