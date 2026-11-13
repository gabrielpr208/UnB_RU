module Controle
  class SessoesController < BaseController
    # Sair não exige ser funcionário: um estudante logado também pode encerrar a sessão por aqui.
    permitir_acesso_sem_login
    before_action :redirecionar_se_logado, only: %i[ new create ]
    rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
      redirect_to login_controle_path, alert: MENSAGEM_DE_MUITAS_TENTATIVAS
    }

    def new
    end

    def create
      funcionario = Funcionario.autenticar(siape: credenciais[:siape], senha: credenciais[:senha])

      if funcionario
        iniciar_sessao_para(funcionario.usuario)
        redirect_to destino_apos_login, notice: "Login realizado com sucesso"
      else
        @siape = credenciais[:siape]
        flash.now[:alert] = MENSAGEM_DE_ERRO_NO_LOGIN
        render :new, status: :unprocessable_content
      end
    end

    def destroy
      encerrar_sessao
      redirect_to login_controle_path, notice: "Você saiu da sua conta", status: :see_other
    end

    private

    def credenciais
      @credenciais ||= params.expect(login: [ :siape, :senha ])
    end
  end
end
