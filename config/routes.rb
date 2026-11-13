Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Cadastro de estudante (features/cadastro_estudante.feature)
  get  "cadastro", to: "cadastros#new", as: :cadastro
  post "cadastro", to: "cadastros#create"

  # Login do estudante (features/login_estudante.feature)
  get    "login",  to: "sessoes#new", as: :login
  post   "login",  to: "sessoes#create"
  delete "logout", to: "sessoes#destroy", as: :logout

  # Página inicial do estudante logado
  root "inicio#show"

  # Recarga de saldo fictícia via PIX ou cartão (features/recarga_saldo.feature)
  get "cardapio", to: "cardapios#show", as: :cardapio

  get  "recarga",                  to: "recargas#new",          as: :nova_recarga
  post "recarga/pix",              to: "recargas#gerar_pix",    as: :gerar_pix
  get  "recarga/pix/:id",          to: "recargas#pix",          as: :recarga_pix
  post "recarga/pix/:id/conferir", to: "recargas#conferir_pix", as: :conferir_pix
  post "recarga/cartao",           to: "recargas#pagar_cartao", as: :pagar_cartao

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
