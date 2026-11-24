# Base de todos os controllers. Exige login em todas as páginas (ver Autenticacao) e só aceita navegadores
# modernos.
class ApplicationController < ActionController::Base
  include Autenticacao

  allow_browser versions: :modern

  stale_when_importmap_changes
end
