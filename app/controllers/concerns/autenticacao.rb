# Login baseado em sessões gravadas no banco (mesmo desenho do gerador de autenticação do Rails 8).
#
# Toda página exige login, a não ser que o controller declare `permitir_acesso_sem_login`.
module Autenticacao
  extend ActiveSupport::Concern

  included do
    before_action :exigir_login
    helper_method :logado?
  end

  class_methods do
    def permitir_acesso_sem_login(**opcoes)
      skip_before_action :exigir_login, **opcoes
    end
  end

  private

  def logado?
    retomar_sessao.present?
  end

  def exigir_login
    retomar_sessao || pedir_login
  end

  def redirecionar_se_logado
    redirect_to root_path if logado?
  end

  def retomar_sessao
    Current.sessao ||= sessao_do_cookie
  end

  def sessao_do_cookie
    Sessao.find_by(id: cookies.signed[:sessao_id]) if cookies.signed[:sessao_id]
  end

  def pedir_login
    session[:retornar_para] = request.url if request.get? || request.head?
    redirect_to login_path, alert: "Você deve estar logado para acessar esta página"
  end

  def destino_apos_login
    session.delete(:retornar_para) || root_path
  end

  def iniciar_sessao_para(usuario)
    usuario.sessoes.create!(user_agent: request.user_agent, endereco_ip: request.remote_ip).tap do |sessao|
      Current.sessao = sessao
      cookies.signed.permanent[:sessao_id] = { value: sessao.id, httponly: true, same_site: :lax }
    end
  end

  def encerrar_sessao
    Current.sessao&.destroy
    cookies.delete(:sessao_id)
    reset_session
  end
end
