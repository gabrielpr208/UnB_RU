require "rails_helper"

RSpec.describe RelatorioAcessos do
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }
  let!(:fce) { Restaurante.create!(nome: "RU FCE", campus: "Ceilândia") }
  let!(:darcy_01) { darcy.catracas.create!(identificador: "01") }
  let!(:darcy_02) { darcy.catracas.create!(identificador: "02") }
  let!(:gama_01) { gama.catracas.create!(identificador: "01") }
  let(:estudante) { criar_estudante }

  def acesso(catraca, dia, hora)
    Acesso.create!(estudante:, catraca:, valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, dia, hora))
  end

  let!(:mais_recente) { acesso(darcy_01, 16, 12) }
  let!(:do_meio) { acesso(darcy_02, 15, 18) }
  let!(:mais_antigo) { acesso(gama_01, 14, 11) }

  def relatorio(**atributos)
    described_class.new(**atributos)
  end

  describe "#acessos" do
    it "lista todos os acessos, do mais recente para o mais antigo" do
      expect(relatorio.acessos).to eq([ mais_recente, do_meio, mais_antigo ])
    end

    it "filtra pelo restaurante" do
      expect(relatorio(restaurante_id: darcy.id).acessos).to eq([ mais_recente, do_meio ])
    end

    it "filtra pela catraca do restaurante" do
      expect(relatorio(restaurante_id: darcy.id, catraca_id: darcy_02.id).acessos).to eq([ do_meio ])
    end

    it "ignora a catraca de outro restaurante e filtra só pelo restaurante" do
      expect(relatorio(restaurante_id: darcy.id, catraca_id: gama_01.id).acessos).to eq([ mais_recente, do_meio ])
    end

    it "ignora a catraca quando nenhum restaurante foi escolhido" do
      expect(relatorio(catraca_id: darcy_02.id).acessos.size).to eq(3)
    end

    it "fica vazio para restaurante sem acessos ou inexistente" do
      expect(relatorio(restaurante_id: fce.id).acessos).to be_empty
      expect(relatorio(restaurante_id: 0).acessos).to be_empty
    end
  end

  describe "#totais" do
    it "agrupa por restaurante, só com os que têm acessos, em ordem alfabética" do
      expect(relatorio(agrupar: "restaurante").totais).to eq([ [ "RU Darcy Ribeiro", 2 ], [ "RU Gama", 1 ] ])
    end

    it "agrupa por catraca, identificando o restaurante" do
      expect(relatorio(agrupar: "catraca").totais)
        .to eq([ [ "RU Darcy Ribeiro - 01", 1 ], [ "RU Darcy Ribeiro - 02", 1 ], [ "RU Gama - 01", 1 ] ])
    end

    it "respeita os filtros" do
      expect(relatorio(restaurante_id: darcy.id, agrupar: "catraca").totais)
        .to eq([ [ "RU Darcy Ribeiro - 01", 1 ], [ "RU Darcy Ribeiro - 02", 1 ] ])
    end

    it "sem agrupamento, ou com um desconhecido, não tem totais" do
      expect(relatorio.totais).to eq([])
      expect(relatorio(agrupar: "estudante").agrupar).to be_nil
    end
  end

  describe "#totais_por_restaurante" do
    it "traz todos os restaurantes, inclusive sem acessos, do mais movimentado para o menos, ignorando filtros" do
      expect(relatorio(restaurante_id: gama.id).totais_por_restaurante)
        .to eq([ [ "RU Darcy Ribeiro", 2 ], [ "RU Gama", 1 ], [ "RU FCE", 0 ] ])
    end
  end

  it "só oferece as catracas do restaurante escolhido" do
    expect(relatorio.catracas_disponiveis).to be_empty
    expect(relatorio(restaurante_id: darcy.id).catracas_disponiveis).to eq([ darcy_01, darcy_02 ])
  end
end
