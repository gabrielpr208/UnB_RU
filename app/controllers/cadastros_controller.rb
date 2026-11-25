# Cadastro público do estudante no Portal do Estudante (features/cadastro_estudante.feature).
class CadastrosController < ApplicationController
  permitir_acesso_sem_login
  before_action :redirecionar_se_logado

  # Mostra o formulário de cadastro em branco.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +new+.
  def new
    @cadastro = CadastroEstudante.new
  end

  # Cadastra o estudante com os dados do formulário.
  #
  # Argumentos:: nenhum; os dados vêm de <tt>params[:cadastro_estudante]</tt> (ver #cadastro_params).
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   com dados válidos, cria o Usuario e o Estudante no banco e redireciona para o login com um aviso de
  #   sucesso; senão, renderiza o formulário com os erros (status 422).
  def create
    @cadastro = CadastroEstudante.new(cadastro_params)

    if @cadastro.save
      redirect_to login_path, notice: "Cadastro realizado com sucesso"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  # Dados permitidos do formulário de cadastro.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActionController::Parameters</tt> com nome, matrícula, e-mail, senha e confirmação.
  # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
  def cadastro_params
    params.expect(cadastro_estudante: [ :nome, :matricula, :email, :senha, :confirmacao_senha ])
  end
end
