# Login baseado em sessões gravadas no banco (mesmo desenho do gerador de autenticação do Rails 8).
#
# Toda página exige login, a não ser que o controller declare `permitir_acesso_sem_login`.
#
# O sistema tem duas áreas, cada uma com o próprio público, login e página inicial:
# - Portal do Estudante (padrão deste módulo): só estudantes, login com matrícula
# - Aplicação de Controle (Controle::BaseController): só funcionários, login com SIAPE
# Quem está logado, mas não pertence à área, volta para o login dela com `mensagem_de_acesso_negado`.
module Autenticacao
  extend ActiveSupport::Concern

  MENSAGEM_DE_ERRO_NO_LOGIN = "Erro na autenticação. Verifique os dados".freeze
  MENSAGEM_DE_MUITAS_TENTATIVAS = "Muitas tentativas de login. Aguarde alguns minutos e tente novamente.".freeze

  included do
    before_action :exigir_login
    helper_method :logado?, :caminho_do_logout
  end

  class_methods do
    def permitir_acesso_sem_login(**opcoes)
      skip_before_action :exigir_login, **opcoes
    end
  end

  private

  # ---------- Configuração da área (a Aplicação de Controle troca todos estes métodos) ----------

  def autorizado?
    Current.usuario.estudante.present?
  end

  def caminho_do_login
    login_path
  end

  def caminho_do_logout
    logout_path
  end

  def caminho_inicial
    root_path
  end

  # Cada controller pode trocar a mensagem para dizer o que o usuário estava tentando ver.
  def mensagem_para_pedir_login
    "Você deve estar logado para acessar esta página"
  end

  def mensagem_de_acesso_negado
    "Acesso permitido apenas para estudantes"
  end

  # Cada área guarda a própria página de retorno, para que o login de uma não leve para a outra.
  def chave_da_pagina_de_retorno
    :retornar_para
  end

  # ---------- Fluxo de login ----------

  def logado?
    retomar_sessao.present?
  end

  def exigir_login
    return pedir_login unless logado?

    redirect_to caminho_do_login, alert: mensagem_de_acesso_negado unless autorizado?
  end

  def redirecionar_se_logado
    redirect_to caminho_inicial if logado? && autorizado?
  end

  def retomar_sessao
    Current.sessao ||= sessao_do_cookie
  end

  def sessao_do_cookie
    Sessao.find_by(id: cookies.signed[:sessao_id]) if cookies.signed[:sessao_id]
  end

  def pedir_login
    session[chave_da_pagina_de_retorno] = request.url if request.get? || request.head?
    redirect_to caminho_do_login, alert: mensagem_para_pedir_login
  end

  def destino_apos_login
    session.delete(chave_da_pagina_de_retorno) || caminho_inicial
  end

  # Uma sessão aberta antes (ex.: estudante que entra como funcionário no mesmo navegador) é encerrada.
  def iniciar_sessao_para(usuario)
    retomar_sessao&.destroy
    usuario.sessoes.create!(user_agent: request.user_agent, endereco_ip: request.remote_ip).tap do |sessao|
      Current.sessao = sessao
      cookies.signed.permanent[:sessao_id] = { value: sessao.id, httponly: true, same_site: :lax }
    end
  end

  def encerrar_sessao
    retomar_sessao&.destroy
    cookies.delete(:sessao_id)
    reset_session
  end
end
