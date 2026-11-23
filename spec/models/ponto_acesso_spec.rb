require "rails_helper"

RSpec.describe PontoAcesso, type: :model do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let(:catraca) { restaurante.catracas.create!(identificador: "01") }
  let(:outra_catraca) { restaurante.catracas.create!(identificador: "02") }
  let(:funcionario) { criar_funcionario(siape: "1234567") }
  let(:colega) { criar_funcionario(siape: "7654321", email: "colega@unb.br") }
  let(:agora) { Time.zone.local(2026, 11, 15, 11, 0) }

  it "é válido com funcionário, catraca e início" do
    expect(described_class.new(funcionario:, catraca:, iniciado_em: agora)).to be_valid
  end

  it "exige funcionário, catraca e início" do
    ponto = described_class.new

    expect(ponto).not_to be_valid
    expect(ponto.errors.attribute_names).to include(:funcionario, :catraca, :iniciado_em)
  end

  it "conhece o restaurante pela catraca" do
    expect(described_class.new(catraca:).restaurante).to eq(restaurante)
  end

  describe ".abrir!" do
    it "abre um ponto em aberto para o funcionário na catraca" do
      ponto = described_class.abrir!(funcionario:, catraca:, agora:)

      expect(ponto).to be_persisted
      expect(ponto).to have_attributes(funcionario:, catraca:, iniciado_em: agora, encerrado_em: nil)
      expect(funcionario.reload.ponto_acesso_atual).to eq(ponto)
    end

    it "encerra o ponto anterior do funcionário quando ele troca de catraca" do
      anterior = described_class.abrir!(funcionario:, catraca:, agora:)
      atual = described_class.abrir!(funcionario:, catraca: outra_catraca, agora: agora + 1.hour)

      expect(anterior.reload.encerrado_em).to eq(agora + 1.hour)
      expect(funcionario.reload.ponto_acesso_atual).to eq(atual)
    end

    it "encerra o ponto de quem estava na catraca, como numa troca de turno" do
      do_colega = described_class.abrir!(funcionario: colega, catraca:, agora:)
      described_class.abrir!(funcionario:, catraca:, agora: agora + 1.hour)

      expect(do_colega.reload.encerrado_em).to eq(agora + 1.hour)
      expect(colega.reload.ponto_acesso_atual).to be_nil
    end

    it "não mexe no ponto de outro funcionário em outra catraca" do
      do_colega = described_class.abrir!(funcionario: colega, catraca: outra_catraca, agora:)
      described_class.abrir!(funcionario:, catraca:, agora: agora + 1.hour)

      expect(do_colega.reload.encerrado_em).to be_nil
    end

    it "guarda o histórico sem mudar o encerramento dos pontos antigos" do
      primeiro = described_class.abrir!(funcionario:, catraca:, agora:)
      described_class.abrir!(funcionario:, catraca: outra_catraca, agora: agora + 1.hour)
      described_class.abrir!(funcionario:, catraca:, agora: agora + 2.hours)

      expect(funcionario.pontos_acesso.count).to eq(3)
      expect(primeiro.reload.encerrado_em).to eq(agora + 1.hour)
    end
  end

  describe ".encerrar" do
    it "encerra só os pontos em aberto da relação" do
      ponto = described_class.abrir!(funcionario:, catraca:, agora:)
      do_colega = described_class.abrir!(funcionario: colega, catraca: outra_catraca, agora:)

      funcionario.pontos_acesso.encerrar(agora + 1.hour)

      expect(ponto.reload.encerrado_em).to eq(agora + 1.hour)
      expect(do_colega.reload.encerrado_em).to be_nil
    end
  end

  describe "regras garantidas pelo banco de dados" do
    it "não aceita dois pontos em aberto do mesmo funcionário" do
      described_class.abrir!(funcionario:, catraca:, agora:)

      expect { described_class.create!(funcionario:, catraca: outra_catraca, iniciado_em: agora) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "não aceita dois pontos em aberto na mesma catraca" do
      described_class.abrir!(funcionario: colega, catraca:, agora:)

      expect { described_class.create!(funcionario:, catraca:, iniciado_em: agora) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "aceita vários pontos encerrados do mesmo funcionário na mesma catraca" do
      2.times { described_class.create!(funcionario:, catraca:, iniciado_em: agora, encerrado_em: agora + 1.hour) }

      expect(described_class.count).to eq(2)
    end

    it "não aceita encerramento antes do início" do
      ponto = described_class.abrir!(funcionario:, catraca:, agora:)

      expect { ponto.update_column(:encerrado_em, agora - 1.minute) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it "é removido junto com o funcionário" do
    described_class.abrir!(funcionario:, catraca:, agora:)

    expect { funcionario.usuario.destroy }.to change(described_class, :count).by(-1)
  end

  it "é removido junto com a catraca" do
    described_class.abrir!(funcionario:, catraca:, agora:)

    expect { catraca.destroy }.to change(described_class, :count).by(-1)
  end
end
