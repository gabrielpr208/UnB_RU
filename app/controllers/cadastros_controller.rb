class CadastrosController < ApplicationController
  def new
    @cadastro = CadastroEstudante.new
  end

  def create
    @cadastro = CadastroEstudante.new(cadastro_params)

    if @cadastro.save
      redirect_to login_path, notice: "Cadastro realizado com sucesso"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def cadastro_params
    params.expect(cadastro_estudante: [ :nome, :matricula, :email, :senha, :confirmacao_senha ])
  end
end
