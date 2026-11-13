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

  it "exige o restaurante" do
    expect(nova_catraca(restaurante: nil)).not_to be_valid
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
end
