# Dados da requisição atual, acessíveis em qualquer parte do código (ex.: <tt>Current.usuario</tt>).
# A sessão é definida pelo login (ver Autenticacao).
class Current < ActiveSupport::CurrentAttributes
  attribute :sessao

  delegate :usuario, to: :sessao, allow_nil: true
end
