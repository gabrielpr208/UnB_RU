require "rails_helper"

RSpec.describe Cardapio, type: :model do
  let(:data) { Date.new(2026, 10, 16) }

  def novo_cardapio(**atributos)
    described_class.new(data:, refeicao: :almoco, **atributos)
  end

  it "é válido com data e refeição" do
    expect(novo_cardapio).to be_valid
  end

  it "exige a data" do
    expect(novo_cardapio(data: nil)).not_to be_valid
  end

  it "recusa refeição desconhecida" do
    expect(novo_cardapio(refeicao: "lanche")).not_to be_valid
  end

  it "não aceita dois cardápios para a mesma refeição na mesma data" do
    novo_cardapio.save!

    repetido = novo_cardapio
    expect(repetido).not_to be_valid
    expect(repetido.errors[:refeicao]).to be_present
  end

  it "aceita a mesma refeição em outra data e outra refeição na mesma data" do
    novo_cardapio.save!

    expect(novo_cardapio(data: data + 1)).to be_valid
    expect(novo_cardapio(refeicao: :jantar)).to be_valid
  end

  describe "#prato" do
    subject(:cardapio) { novo_cardapio.tap(&:save!) }

    before do
      cardapio.itens.create!(categoria: "prato_principal", variante: :padrao, descricao: "Frango grelhado")
      cardapio.itens.create!(categoria: "prato_principal", variante: :ovolactovegetariano, descricao: "Omelete de legumes")
      cardapio.itens.create!(categoria: "bebida", variante: :vegetariano_estrito, descricao: "Suco")
    end

    it "devolve o prato principal da variante" do
      expect(cardapio.prato(:padrao)).to eq("Frango grelhado")
      expect(cardapio.prato("ovolactovegetariano")).to eq("Omelete de legumes")
    end

    it "devolve nil quando a opção não foi cadastrada" do
      expect(cardapio.prato(:vegetariano_estrito)).to be_nil
    end
  end

  it "remove os itens junto com o cardápio" do
    cardapio = novo_cardapio.tap(&:save!)
    cardapio.itens.create!(categoria: "prato_principal", variante: :padrao, descricao: "Frango")

    expect { cardapio.destroy }.to change(ItemCardapio, :count).by(-1)
  end
end
