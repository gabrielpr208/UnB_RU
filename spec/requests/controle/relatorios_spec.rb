require "rails_helper"

RSpec.describe "Histórico de acessos", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }
  let!(:darcy_01) { darcy.catracas.create!(identificador: "01") }
  let!(:gama_01) { gama.catracas.create!(identificador: "01") }
  let!(:estudante) { criar_estudante(matricula: "231012345") }

  before do
    Acesso.create!(estudante:, catraca: darcy_01, valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 16, 12, 30))
    Acesso.create!(estudante:, catraca: gama_01, valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 15, 12, 5))
  end

  def html
    Nokogiri::HTML5(response.body)
  end

  def linhas
    html.css("#acessos tbody tr").map { |linha| linha.css("td").map { |celula| celula.text.strip } }
  end

  describe "acesso" do
    it "pede login a quem não está logado" do
      get controle_relatorio_path

      expect(response).to redirect_to(login_controle_path)
    end

    it "manda o funcionário que não é administrador de volta para o início" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))
      get controle_relatorio_path

      expect(response).to redirect_to(controle_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")
    end
  end

  context "como administrador" do
    before { entrar_como_funcionario(administrador) }

    it "lista os acessos com estudante, restaurante, catraca e data e hora" do
      get controle_relatorio_path

      expect(response).to have_http_status(:ok)
      expect(linhas).to eq([
        [ "231012345", "RU Darcy Ribeiro", "01", "16/10/2026 12:30" ],
        [ "231012345", "RU Gama", "01", "15/10/2026 12:05" ]
      ])
      expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Relatório" ])
    end

    it "deixa o filtro de catraca desabilitado até escolher o restaurante" do
      get controle_relatorio_path

      expect(html.at("select#catraca_id")["disabled"]).to be_present
      expect(html.at(".campo__dica").text).to eq("Selecione um restaurante para filtrar por catraca")
    end

    it "com o restaurante escolhido, oferece só as catracas dele" do
      get controle_relatorio_path(restaurante_id: gama.id)

      expect(html.at("select#catraca_id")["disabled"]).to be_nil
      expect(html.css("select#catraca_id option").map(&:text)).to eq([ "Todas as catracas", "01" ])
      expect(linhas.map { |linha| linha[1] }).to eq([ "RU Gama" ])
    end

    it "mostra os totais quando agrupa" do
      get controle_relatorio_path(agrupar: "restaurante")

      totais = html.css("#totais tbody tr").map { |linha| linha.css("td").map(&:text) }
      expect(totais).to eq([ [ "RU Darcy Ribeiro", "1" ], [ "RU Gama", "1" ] ])
    end

    it "avisa quando o filtro não encontra acessos" do
      fce = Restaurante.create!(nome: "RU FCE", campus: "Ceilândia")

      get controle_relatorio_path(restaurante_id: fce.id)

      expect(response.body).to include("Nenhum acesso encontrado para os filtros selecionados")
      expect(html.at("#acessos")).to be_nil
    end
  end
end
