module Controle
  # Login e logout de funcionário na Aplicação de Controle, com o SIAPE e a senha. O login aceita até 10
  # tentativas a cada 3 minutos.
  class SessoesController < BaseController
    # Sair não exige ser funcionário: um estudante logado também pode encerrar a sessão por aqui.
    permitir_acesso_sem_login
    before_action :redirecionar_se_logado, only: %i[ new create ]
    rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
      redirect_to login_controle_path, alert: MENSAGEM_DE_MUITAS_TENTATIVAS
    }

    # Mostra o formulário de login de funcionário.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais:: renderiza a view +new+.
    def new
    end

    # Autentica o funcionário pelo SIAPE e senha e abre a sessão.
    #
    # Argumentos:: nenhum; o SIAPE e a senha vêm de <tt>params[:login]</tt> (ver #credenciais).
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   com credenciais corretas, cria a Sessao no banco, grava o cookie e redireciona para a página que o
    #   funcionário tentou abrir (ou a inicial); senão, renderiza o formulário com o erro (status 422).
    def create
      funcionario = Funcionario.autenticar(siape: credenciais[:siape], senha: credenciais[:senha])

      if funcionario
        concluir_login(funcionario.usuario)
      else
        recusar_login
      end
    end

    # Faz o logout e libera a catraca que o funcionário estava operando.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   encerra o ponto de acesso em aberto, apaga a sessão do banco, remove o cookie e redireciona para o login
    #   de funcionário.
    def destroy
      liberar_catraca
      encerrar_sessao
      redirect_to login_controle_path, notice: "Você saiu da sua conta", status: :see_other
    end

    private

    # Encerra o ponto de acesso do funcionário que está saindo: no próximo login, ele escolhe de novo a catraca.
    #
    # Argumentos:: nenhum.
    # Retorno:: +Integer+ com a quantidade de pontos encerrados, ou +nil+ se quem está saindo não é funcionário.
    # Efeitos colaterais:: preenche +encerrado_em+ do ponto em aberto no banco.
    def liberar_catraca
      retomar_sessao&.usuario&.funcionario&.encerrar_ponto_acesso
    end

    # Recusa o login com uma mensagem genérica, que não diz se o erro foi no SIAPE ou na senha.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   guarda o SIAPE digitado em <tt>@siape</tt> para o formulário mostrá-lo de novo, define o alerta
    #   +MENSAGEM_DE_ERRO_NO_LOGIN+ e renderiza o formulário (status 422).
    def recusar_login
      @siape = credenciais[:siape]
      flash.now[:alert] = MENSAGEM_DE_ERRO_NO_LOGIN
      render :new, status: :unprocessable_content
    end

    # Dados permitidos do formulário de login.
    #
    # Argumentos:: nenhum.
    # Retorno:: <tt>ActionController::Parameters</tt> com +siape+ e +senha+, memorizado entre as chamadas.
    # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
    def credenciais
      @credenciais ||= params.expect(login: [ :siape, :senha ])
    end
  end
end
