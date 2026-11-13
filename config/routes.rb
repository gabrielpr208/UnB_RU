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
  get  "recarga",                  to: "recargas#new",          as: :nova_recarga
  post "recarga/pix",              to: "recargas#gerar_pix",    as: :gerar_pix
  get  "recarga/pix/:id",          to: "recargas#pix",          as: :recarga_pix
  post "recarga/pix/:id/conferir", to: "recargas#conferir_pix", as: :conferir_pix
  post "recarga/cartao",           to: "recargas#pagar_cartao", as: :pagar_cartao

  # Extrato de recargas e refeições, com filtros (features/extrato.feature)
  get "extrato", to: "extratos#show", as: :extrato

  # Aplicação de Controle, só para funcionários: login com SIAPE (features/autenticacao_funcionario.feature)
  scope "controle", module: "controle" do
    get    "login",  to: "sessoes#new",     as: :login_controle
    post   "login",  to: "sessoes#create"
    delete "logout", to: "sessoes#destroy", as: :logout_controle
  end
  get "controle", to: "controle/inicio#show", as: :controle

  # Gestão de restaurantes pelo administrador (features/gerencia_restaurantes.feature)
  namespace :controle do
    resources :restaurantes, except: :show
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
