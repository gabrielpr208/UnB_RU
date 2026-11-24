# Aplicação de Controle: área dos funcionários do RU, com o ponto de acesso, a operação da catraca e as telas de
# gestão do administrador.
module Controle
  # Base dos controllers da Aplicação de Controle. Só funcionários entram; quem está logado como estudante volta
  # para o login de funcionário. Redefine a configuração de área de Autenticacao.
  class BaseController < ApplicationController
    # Restringe ações do controller a administradores (ex.: gestão de restaurantes e catracas).
    #
    # Argumentos::
    #   - +opcoes+: opções de +before_action+ para limitar as ações restritas (ex.: <tt>only: :pdf</tt>).
    # Retorno:: nenhum.
    # Efeitos colaterais:: adiciona o filtro #exigir_administrador às ações indicadas (ou a todas).
    def self.somente_administradores(**opcoes)
      before_action :exigir_administrador, **opcoes
    end

    private

    # Filtro que barra funcionários que não são administradores.
    #
    # Argumentos:: nenhum.
    # Retorno:: nenhum.
    # Efeitos colaterais::
    #   redireciona para a página inicial da Aplicação de Controle com
    #   #mensagem_para_quem_nao_e_administrador quando o funcionário não é administrador.
    def exigir_administrador
      return if Current.usuario.funcionario.administrador?

      redirect_to controle_path, alert: mensagem_para_quem_nao_e_administrador
    end

    # Mensagem mostrada ao funcionário que tenta abrir uma tela de administrador. Cada controller pode trocá-la
    # (ex.: o PDF do relatório de operação).
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com a mensagem.
    # Efeitos colaterais:: nenhum.
    def mensagem_para_quem_nao_e_administrador
      "Acesso permitido apenas para administradores"
    end

    # Diz se o usuário logado pode usar a Aplicação de Controle.
    #
    # Argumentos:: nenhum.
    # Retorno:: +true+ se o usuário logado é funcionário; +false+ caso contrário.
    # Efeitos colaterais:: nenhum.
    def autorizado?
      Current.usuario.funcionario.present?
    end

    # Caminho da tela de login de funcionário.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com o caminho do login da Aplicação de Controle.
    # Efeitos colaterais:: nenhum.
    def caminho_do_login
      login_controle_path
    end

    # Caminho usado pelo botão "Sair" da Aplicação de Controle. Também disponível nas views.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com o caminho do logout da Aplicação de Controle.
    # Efeitos colaterais:: nenhum.
    def caminho_do_logout
      logout_controle_path
    end

    # Página inicial da Aplicação de Controle.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com o caminho da página inicial da Aplicação de Controle.
    # Efeitos colaterais:: nenhum.
    def caminho_inicial
      controle_path
    end

    # Mensagem mostrada a quem está logado como estudante e tenta entrar na Aplicação de Controle.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com a mensagem.
    # Efeitos colaterais:: nenhum.
    def mensagem_de_acesso_negado
      "Acesso por estudantes não autorizado"
    end

    # Chave da sessão em que fica a página da Aplicação de Controle que o usuário tentou abrir antes do login.
    #
    # Argumentos:: nenhum.
    # Retorno:: +Symbol+ com a chave (+:retornar_para_controle+).
    # Efeitos colaterais:: nenhum.
    def chave_da_pagina_de_retorno
      :retornar_para_controle
    end
  end
end
