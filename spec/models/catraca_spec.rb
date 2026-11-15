require "rails_helper"

RSpec.describe Catraca, type: :model do
  let(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }

  def nova_catraca(identificador = "01", restaurante: self.restaurante)
    described_class.new(restaurante:, identificador:)
  end

  def erros_do_identificador(catraca)
    catraca.validate
    catraca.errors[:identificador]
  end

  it "é válida com restaurante e identificador de 2 dígitos" do
    expect(nova_catraca).to be_valid
  end

  it "exige o restaurante, pedindo que ele seja selecionado" do
    catraca = nova_catraca(restaurante: nil)

    expect(catraca).not_to be_valid
    expect(catraca.errors[:restaurante]).to eq([ "Selecione um restaurante" ])
  end

  it "tira espaços em volta do identificador" do
    expect(nova_catraca(" 01 ").identificador).to eq("01")
  end

  it "exige o identificador" do
    catraca = nova_catraca("")

    expect(catraca).not_to be_valid
    expect(catraca.errors[:identificador]).to eq([ "O identificador é obrigatório" ])
  end

  it "só aceita identificador com 2 dígitos numéricos" do
    %w[ 1 123 AB ].each do |identificador|
      expect(erros_do_identificador(nova_catraca(identificador))).to eq([ "O identificador deve ter 2 dígitos numéricos" ])
    end
  end

  it "não repete identificador no mesmo restaurante, mas aceita em outro" do
    nova_catraca.save!
    outro = Restaurante.create!(nome: "RU Gama", campus: "Gama")

    expect(erros_do_identificador(nova_catraca)).to eq([ "Já existe uma catraca com este identificador neste restaurante" ])
    expect(nova_catraca(restaurante: outro)).to be_valid
  end

  describe "em uso e remoção" do
    let!(:catraca) { nova_catraca.tap(&:save!) }
    let(:funcionario) { criar_funcionario }

    it "fica em uso enquanto há um ponto de acesso em aberto nela" do
      expect(catraca).not_to be_em_uso

      PontoAcesso.abrir!(funcionario:, catraca:)
      expect(catraca).to be_em_uso
      expect(catraca.ponto_acesso_atual.funcionario).to eq(funcionario)

      funcionario.encerrar_ponto_acesso
      expect(catraca).not_to be_em_uso
      expect(catraca.reload.ponto_acesso_atual).to be_nil
    end

    it "remove a catraca livre, junto com os pontos de acesso já encerrados" do
      PontoAcesso.abrir!(funcionario:, catraca:)
      funcionario.encerrar_ponto_acesso

      expect(catraca.remover).to be_truthy
      expect(described_class.exists?(catraca.id)).to be(false)
      expect(PontoAcesso.where(catraca_id: catraca.id)).to be_empty
    end

    it "não remove a catraca em uso e explica o motivo" do
      PontoAcesso.abrir!(funcionario:, catraca:)

      expect(catraca.remover).to be(false)
      expect(catraca.errors[:base]).to eq([ "Não é possível remover uma catraca em uso" ])
      expect(described_class.exists?(catraca.id)).to be(true)
    end

    it "não remove a catraca com histórico e explica o motivo" do
      catraca.acessos.create!(estudante: criar_estudante, data_hora: Time.current, valor_cobrado: 4.50)

      expect(catraca.remover).to be(false)
      expect(catraca.errors[:base]).to eq([ "Não é possível remover uma catraca com acessos registrados" ])
      expect(described_class.exists?(catraca.id)).to be(true)
    end
  end


  it "lista por nome do restaurante e depois por identificador" do
    gama = Restaurante.create!(nome: "RU Gama", campus: "Gama")
    gama.catracas.create!(identificador: "01")
    restaurante.catracas.create!(identificador: "02")
    restaurante.catracas.create!(identificador: "01")

    expect(described_class.em_ordem.map { |c| [ c.restaurante.nome, c.identificador ] })
      .to eq([ [ "RU Darcy Ribeiro", "01" ], [ "RU Darcy Ribeiro", "02" ], [ "RU Gama", "01" ] ])
  end
end
