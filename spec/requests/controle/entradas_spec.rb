require "rails_helper"

RSpec.describe "Entradas", type: :request do
  let!(:funcionario) { criar_funcionario }

  context "sem login" do
    it "redireciona para o login de funcionário pedindo que ele entre" do
      get controle_entrada_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
    end
  end

  context "sem ponto de acesso configurado" do
    before { entrar_como_funcionario(funcionario) }

    it "redireciona para a configuração do ponto de acesso" do
      get controle_entrada_path

      expect(response).to redirect_to(controle_ponto_acesso_path)
      expect(flash[:alert]).to eq("Configure o ponto de acesso antes de operar a catraca")
    end
  end

  context "com ponto de acesso configurado" do
    let(:catraca) { catraca_padrao }
    let!(:estudante) { criar_estudante(matricula: "231012345").tap { |e| e.update!(saldo: 4.50) } }

    before do
      travel_to Time.zone.local(2026, 10, 16, 12)
      PrecoRefeicao.create!(refeicao: "almoco", valor: 4.50)
      PontoAcesso.abrir!(funcionario:, catraca:)
      entrar_como_funcionario(funcionario)
    end

    it "mostra a catraca bloqueada" do
      get controle_entrada_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-catraca="bloqueada"))
    end

    it "libera a entrada e volta para a catraca com a mensagem" do
      post controle_entrada_path, params: { matricula: "231012345" }

      expect(response).to redirect_to(controle_entrada_path)
      expect(flash[:notice]).to eq("Entrada liberada")
      expect(flash[:catraca]).to eq("liberada")
    end

    it "recusa a entrada mostrando o motivo" do
      post controle_entrada_path, params: { matricula: "200000000" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Identificação inválida")
    end
  end
end
