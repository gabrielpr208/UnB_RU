class SessoesController < ApplicationController
  # Sair não exige ser estudante: um funcionário logado também pode encerrar a sessão por aqui.
  permitir_acesso_sem_login
  before_action :redirecionar_se_logado, only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to login_path, alert: MENSAGEM_DE_MUITAS_TENTATIVAS
  }

  def new
  end

  def create
    estudante = Estudante.autenticar(matricula: credenciais[:matricula], senha: credenciais[:senha])

    if estudante
      iniciar_sessao_para(estudante.usuario)
      redirect_to destino_apos_login, notice: "Login realizado com sucesso"
    else
      @matricula = credenciais[:matricula]
      flash.now[:alert] = MENSAGEM_DE_ERRO_NO_LOGIN
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    encerrar_sessao
    redirect_to login_path, notice: "Você saiu da sua conta", status: :see_other
  end

  private

  def credenciais
    @credenciais ||= params.expect(login: [ :matricula, :senha ])
  end
end
