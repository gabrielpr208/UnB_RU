# Sessão de login de um usuário, aberta num navegador e identificada pelo cookie +sessao_id+ (ver Autenticacao).
class Sessao < ApplicationRecord
  belongs_to :usuario
end
