require "rails_helper"

RSpec.describe "Históricos", type: :request do
  let!(:funcionario) { criar_funcionario }

  context "sem login" do
    it "redireciona para o login de funcionário" do
      get controle_historico_path

      expect(response).to redirect_to(login_controle_path)
    end
  end

  context "sem ponto de acesso configurado" do
    before { entrar_como_funcionario(funcionario) }

    it "redireciona para a configuração do ponto de acesso" do
      get controle_historico_path

      expect(response).to redirect_to(controle_ponto_acesso_path)
      expect(flash[:alert]).to eq("Você deve ter uma catraca configurada para ver o histórico")
    end
  end

  context "com ponto de acesso configurado" do
    let(:estudante) { criar_estudante(matricula: "231012345") }

    before do
      PontoAcesso.abrir!(funcionario:, catraca: catraca_padrao)
      entrar_como_funcionario(funcionario)
    end

    it "mostra os acessos da catraca" do
      catraca_padrao.acessos.create!(estudante:, data_hora: Time.zone.local(2026, 10, 12, 12), valor_cobrado: 4.5)

      get controle_historico_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("231012345")
    end

    it "não mostra acessos de outra catraca" do
      outra = catraca_padrao.restaurante.catracas.create!(identificador: "02")
      outra.acessos.create!(estudante:, data_hora: Time.zone.local(2026, 10, 12, 12), valor_cobrado: 4.5)

      get controle_historico_path

      expect(response.body).not_to include("231012345")
    end
  end
end
