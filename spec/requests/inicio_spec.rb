require "rails_helper"

RSpec.describe "Página inicial do estudante", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345") }

  context "sem login" do
    it "redireciona para o login pedindo que o estudante entre" do
      get root_path

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
    end
  end

  context "logado como funcionário" do
    before { entrar_como_funcionario(criar_funcionario) }

    it "redireciona para o login do estudante avisando que a página é só para estudantes" do
      get root_path

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para estudantes")
    end

    it "deixa o funcionário ver o login do estudante, sem redirecionar de novo" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login do estudante")
    end
  end

  context "com login" do
    before do
      estudante.update!(saldo: BigDecimal("1234.5"))
      entrar_como(estudante)
      get root_path
    end

    it "cumprimenta o estudante pelo primeiro nome" do
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Olá, Estudante")
    end

    it "mostra o saldo formatado em reais" do
      expect(response.body).to include("R$ 1.234,50")
    end

    it "mostra os dados da conta" do
      expect(response.body).to include("231012345")
      expect(response.body).to include("existente@aluno.unb.br")
    end

    it "mostra o usuário logado e o botão de sair no cabeçalho" do
      expect(response.body).to include("Estudante Existente")
      expect(response.body).to match(%r{<form[^>]+action="#{logout_path}"})
    end
  end
end
