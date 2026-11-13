# Aplicação de Controle: área dos funcionários do RU, onde ficarão a gestão de restaurantes e catracas.
# Só funcionários entram; quem está logado como estudante volta para o login de funcionário.
module Controle
  class BaseController < ApplicationController
    # Telas que só o administrador usa (ex.: gestão de restaurantes e catracas).
    def self.somente_administradores(**opcoes)
      before_action :exigir_administrador, **opcoes
    end

    private

    def exigir_administrador
      return if Current.usuario.funcionario.administrador?

      redirect_to controle_path, alert: "Acesso permitido apenas para administradores"
    end

    def autorizado?
      Current.usuario.funcionario.present?
    end

    def caminho_do_login
      login_controle_path
    end

    def caminho_do_logout
      logout_controle_path
    end

    def caminho_inicial
      controle_path
    end

    def mensagem_de_acesso_negado
      "Acesso por estudantes não autorizado"
    end

    def chave_da_pagina_de_retorno
      :retornar_para_controle
    end
  end
end
