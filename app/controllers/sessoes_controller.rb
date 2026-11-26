# Login e logout do estudante no Portal do Estudante, com a matrícula e a senha. O login aceita até 10
# tentativas a cada 3 minutos.
class SessoesController < ApplicationController
  permitir_acesso_sem_login
  before_action :redirecionar_se_logado, only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: lambda {
    redirect_to login_path, alert: MENSAGEM_DE_MUITAS_TENTATIVAS
  }

  # Mostra o formulário de login do estudante.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +new+.
  def new
  end

  # Autentica o estudante pela matrícula e senha e abre a sessão.
  #
  # Argumentos:: nenhum; a matrícula e a senha vêm de <tt>params[:login]</tt> (ver #credenciais).
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   com credenciais corretas, cria a Sessao no banco, grava o cookie e redireciona para a página que o
  #   estudante tentou abrir (ou a inicial); senão, renderiza o formulário com o erro (status 422).
  def create
    estudante = Estudante.autenticar(matricula: credenciais[:matricula], senha: credenciais[:senha])

    if estudante
      concluir_login(estudante.usuario)
    else
      recusar_login
    end
  end

  # Faz o logout do estudante.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: apaga a sessão do banco, remove o cookie e redireciona para o login.
  def destroy
    encerrar_sessao
    redirect_to login_path, notice: "Você saiu da sua conta", status: :see_other
  end

  private

  # Recusa o login com uma mensagem genérica, que não diz se o erro foi na matrícula ou na senha.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   guarda a matrícula digitada em <tt>@matricula</tt> para o formulário mostrá-la de novo, define o alerta
  #   +MENSAGEM_DE_ERRO_NO_LOGIN+ e renderiza o formulário (status 422).
  def recusar_login
    @matricula = credenciais[:matricula]
    flash.now[:alert] = MENSAGEM_DE_ERRO_NO_LOGIN
    render :new, status: :unprocessable_content
  end

  # Dados permitidos do formulário de login.
  #
  # Argumentos:: nenhum.
  # Retorno:: <tt>ActionController::Parameters</tt> com +matricula+ e +senha+, memorizado entre as chamadas.
  # Efeitos colaterais:: responde 400 (Bad Request) se os parâmetros não tiverem o formato esperado.
  def credenciais
    @credenciais ||= params.expect(login: [ :matricula, :senha ])
  end
end
