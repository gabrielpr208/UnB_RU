# Aplicação de Controle: área dos funcionários do RU, onde ficarão a gestão de restaurantes e catracas.
# Só funcionários entram; quem está logado como estudante volta para o login de funcionário.
module Controle
  class BaseController < ApplicationController
    private

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
