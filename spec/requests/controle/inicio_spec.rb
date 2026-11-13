require "rails_helper"

RSpec.describe "Página inicial da Aplicação de Controle", type: :request do
  let!(:funcionario) { criar_funcionario(siape: "1234567") }

  context "sem login" do
    it "redireciona para o login de funcionário pedindo que ele entre" do
      get controle_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
    end
  end

  context "logado como estudante" do
    before { entrar_como(criar_estudante) }

    it "redireciona para o login de funcionário avisando que estudantes não têm acesso" do
      get controle_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Acesso por estudantes não autorizado")
    end
  end

  context "logado como funcionário" do
    before do
      entrar_como_funcionario(funcionario)
      get controle_path
    end

    it "cumprimenta o funcionário pelo primeiro nome" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá, Funcionário")
    end

    it "mostra os dados do funcionário" do
      expect(response.body).to include("1234567")
      expect(response.body).to include("funcionario@unb.br")
    end

    it "mostra o funcionário logado e o botão de sair da Aplicação de Controle no cabeçalho" do
      expect(response.body).to include("Funcionário Existente")
      expect(response.body).to include("Funcionário · SIAPE 1234567")
      expect(response.body).to match(%r{<form[^>]+action="#{logout_controle_path}"})
    end
  end

  context "logado como administrador" do
    it "mostra o perfil de administrador" do
      administrador = criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true)
      entrar_como_funcionario(administrador)
      get controle_path

      expect(response.body).to include("Administrador · SIAPE 7654321")
    end
  end
end
