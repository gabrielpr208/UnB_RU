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

  # Cardápio da refeição atual (features/cardapio_refeicao_atual.feature)
  get "cardapio", to: "cardapios#show", as: :cardapio

  # Recarga de saldo fictícia via PIX ou cartão (features/recarga_saldo.feature)
  get  "recarga",                  to: "recargas#new",          as: :nova_recarga
  post "recarga/pix",              to: "recargas#gerar_pix",    as: :gerar_pix
  get  "recarga/pix/:id",          to: "recargas#pix",          as: :recarga_pix
  post "recarga/pix/:id/conferir", to: "recargas#conferir_pix", as: :conferir_pix
  post "recarga/cartao",           to: "recargas#pagar_cartao", as: :pagar_cartao

  # Extrato de recargas e refeições, com filtros (features/extrato.feature)
  get "extrato", to: "extratos#show", as: :extrato
  # Exportação do extrato em PDF, com os mesmos filtros (features/pdf_historico_estudante.feature)
  get "extrato/pdf", to: "extratos#pdf", as: :extrato_pdf

  # Aplicação de Controle, só para funcionários: login com SIAPE (features/autenticacao_funcionario.feature)
  scope "controle", module: "controle" do
    get    "login",  to: "sessoes#new",     as: :login_controle
    post   "login",  to: "sessoes#create"
    delete "logout", to: "sessoes#destroy", as: :logout_controle
  end
  get "controle", to: "controle/inicio#show", as: :controle

  namespace :controle do
    # Escolha do restaurante e da catraca em que o funcionário vai operar (features/configuracao_ponto_acesso.feature)
    get  "ponto-de-acesso", to: "pontos_acesso#new", as: :ponto_acesso
    post "ponto-de-acesso", to: "pontos_acesso#create"

    # Gestão de restaurantes pelo administrador (features/gerencia_restaurantes.feature)
    resources :restaurantes, except: :show

    # Gestão de catracas pelo administrador (features/gerencia_catracas.feature)
    resources :catracas, except: :show

    # Gestão de funcionários pelo administrador (features/cadastro_funcionario.feature e gerencia_funcionarios.feature)
    resources :funcionarios, except: :show

    get "entrada", to: "entradas#new", as: :entrada
    post "entrada", to: "entradas#create"

    # Histórico de todos os acessos, para o administrador (features/relatorio_global.feature)
    get "relatorio", to: "relatorios#show", as: :relatorio
    # Relatório Global de Operação em PDF (features/pdf_relatorio.feature)
    get "relatorio/pdf", to: "relatorios#pdf", as: :relatorio_pdf

    get "historico", to: "historicos#index", as: :historico
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
