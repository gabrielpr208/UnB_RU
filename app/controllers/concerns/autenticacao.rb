# Login baseado em sessões gravadas no banco (mesmo desenho do gerador de autenticação do Rails 8).
#
# Toda página exige login, a não ser que o controller declare +permitir_acesso_sem_login+.
#
# O sistema tem duas áreas, cada uma com o próprio público, login e página inicial:
# - Portal do Estudante (padrão deste módulo): só estudantes, login com matrícula
# - Aplicação de Controle (Controle::BaseController): só funcionários, login com SIAPE
# Quem está logado, mas não pertence à área, volta para o login dela com +mensagem_de_acesso_negado+.
module Autenticacao
  extend ActiveSupport::Concern

  # Mensagem mostrada quando a identificação ou a senha não conferem.
  MENSAGEM_DE_ERRO_NO_LOGIN = "Erro na autenticação. Verifique os dados".freeze
  # Mensagem mostrada quando o limite de tentativas de login é atingido.
  MENSAGEM_DE_MUITAS_TENTATIVAS = "Muitas tentativas de login. Aguarde alguns minutos e tente novamente.".freeze

  included do
    before_action :exigir_login
    helper_method :logado?, :caminho_do_logout
  end

  # Métodos de classe adicionados aos controllers que incluem Autenticacao.
  module ClassMethods
    # Libera as ações do controller do login obrigatório.
    #
    # Argumentos::
    #   - +opcoes+: opções de +skip_before_action+ para limitar as ações liberadas (ex.: <tt>only: :show</tt>).
    # Retorno:: nenhum.
    # Efeitos colaterais:: remove o filtro +exigir_login+ das ações indicadas (ou de todas).
    def permitir_acesso_sem_login(**opcoes)
      skip_before_action :exigir_login, **opcoes
    end
  end

  private

  # :section: Configuração da área
  # Métodos que definem o público, os caminhos e as mensagens de cada área. Estes são os do Portal do
  # Estudante; a Aplicação de Controle (Controle::BaseController) redefine todos eles.

  # Diz se o usuário logado pode usar a área.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se o usuário logado é estudante; +false+ caso contrário.
  # Efeitos colaterais:: nenhum.
  def autorizado?
    Current.usuario.estudante.present?
  end

  # Caminho da tela de login da área.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com o caminho do login do Portal do Estudante.
  # Efeitos colaterais:: nenhum.
  def caminho_do_login
    login_path
  end

  # Caminho usado pelo botão "Sair" da área. Também disponível nas views.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com o caminho do logout do Portal do Estudante.
  # Efeitos colaterais:: nenhum.
  def caminho_do_logout
    logout_path
  end

  # Página inicial da área, aberta depois do login quando não há página de retorno.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com o caminho da página inicial do Portal do Estudante.
  # Efeitos colaterais:: nenhum.
  def caminho_inicial
    root_path
  end

  # Mensagem mostrada a quem tenta abrir uma página sem estar logado. Cada controller pode trocá-la para dizer o
  # que o usuário estava tentando ver.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com a mensagem.
  # Efeitos colaterais:: nenhum.
  def mensagem_para_pedir_login
    "Você deve estar logado para acessar esta página"
  end

  # Mensagem mostrada a quem está logado, mas não pertence à área.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com a mensagem.
  # Efeitos colaterais:: nenhum.
  def mensagem_de_acesso_negado
    "Acesso permitido apenas para estudantes"
  end

  # Chave da sessão em que fica a página que o usuário tentou abrir antes do login. Cada área usa a sua, para
  # que o login de uma não leve para a outra.
  #
  # Argumentos:: nenhum.
  # Retorno:: +Symbol+ com a chave (+:retornar_para+).
  # Efeitos colaterais:: nenhum.
  def chave_da_pagina_de_retorno
    :retornar_para
  end

  # :section: Fluxo de login
  # Métodos que abrem, retomam e encerram a sessão do usuário, iguais nas duas áreas.

  # Diz se há um usuário logado. Também disponível nas views.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se o cookie aponta para uma sessão existente; +false+ caso contrário.
  # Efeitos colaterais:: guarda a sessão em <tt>Current.sessao</tt> (ver #retomar_sessao).
  def logado?
    retomar_sessao.present?
  end

  # Filtro executado antes de toda ação: só deixa passar quem está logado e pertence à área.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   sem login, redireciona para o login guardando a página pedida (ver #pedir_login); logado fora da área,
  #   redireciona para o login com +mensagem_de_acesso_negado+.
  def exigir_login
    return pedir_login unless logado?

    redirect_to caminho_do_login, alert: mensagem_de_acesso_negado unless autorizado?
  end

  # Filtro das telas de login e cadastro: quem já está logado na área vai direto para a página inicial.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: redireciona para +caminho_inicial+ quando o usuário já está logado e autorizado.
  def redirecionar_se_logado
    redirect_to caminho_inicial if logado? && autorizado?
  end

  # Sessão do usuário logado, lida do cookie uma única vez por requisição.
  #
  # Argumentos:: nenhum.
  # Retorno:: a Sessao, ou +nil+ se não há login.
  # Efeitos colaterais:: guarda a sessão em <tt>Current.sessao</tt>.
  def retomar_sessao
    Current.sessao ||= sessao_do_cookie
  end

  # Busca a sessão cujo id está no cookie assinado +sessao_id+.
  #
  # Argumentos:: nenhum.
  # Retorno:: a Sessao, ou +nil+ se o cookie não existe ou aponta para uma sessão encerrada.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def sessao_do_cookie
    Sessao.find_by(id: cookies.signed[:sessao_id]) if cookies.signed[:sessao_id]
  end

  # Manda o usuário para o login da área, lembrando a página que ele tentou abrir.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   em requisições GET e HEAD, guarda a URL pedida na sessão; redireciona para o login com
  #   +mensagem_para_pedir_login+.
  def pedir_login
    session[chave_da_pagina_de_retorno] = request.url if request.get? || request.head?
    redirect_to caminho_do_login, alert: mensagem_para_pedir_login
  end

  # Página para onde o usuário vai depois do login.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com a página que ele tentou abrir antes do login ou, se não houver, a página inicial.
  # Efeitos colaterais:: remove a página de retorno da sessão.
  def destino_apos_login
    session.delete(chave_da_pagina_de_retorno) || caminho_inicial
  end

  # Abre uma sessão para o usuário que acabou de se autenticar. Uma sessão aberta antes (ex.: estudante que
  # entra como funcionário no mesmo navegador) é encerrada.
  #
  # Argumentos::
  #   - +usuario+: Usuario autenticado.
  # Retorno:: a Sessao criada.
  # Efeitos colaterais::
  #   apaga do banco a sessão anterior, cria uma Sessao com o navegador e o IP da requisição, guarda-a em
  #   <tt>Current.sessao</tt> e grava o id no cookie assinado e permanente +sessao_id+.
  def iniciar_sessao_para(usuario)
    retomar_sessao&.destroy
    usuario.sessoes.create!(user_agent: request.user_agent, endereco_ip: request.remote_ip).tap do |sessao|
      Current.sessao = sessao
      cookies.signed.permanent[:sessao_id] = { value: sessao.id, httponly: true, same_site: :lax }
    end
  end

  # Conclui um login bem-sucedido: abre a sessão e leva o usuário para onde ele queria ir. Usado pelo login
  # do estudante e pelo de funcionário.
  #
  # Argumentos::
  #   - +usuario+: Usuario que acabou de se autenticar.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   abre a sessão (ver #iniciar_sessao_para) e redireciona para a página que o usuário tentou abrir antes
  #   do login (ou a inicial) com o aviso "Login realizado com sucesso".
  def concluir_login(usuario)
    iniciar_sessao_para(usuario)
    redirect_to destino_apos_login, notice: "Login realizado com sucesso"
  end

  # Faz o logout do usuário.
  #
  # Argumentos:: nenhum.
  # Retorno:: nenhum.
  # Efeitos colaterais:: apaga a sessão do banco, remove o cookie +sessao_id+ e limpa a sessão do Rails.
  def encerrar_sessao
    retomar_sessao&.destroy
    cookies.delete(:sessao_id)
    reset_session
  end
end
