require "rails_helper"

RSpec.describe ItemCardapio, type: :model do
  let(:cardapio) { Cardapio.create!(data: Date.new(2026, 10, 16), refeicao: :almoco) }

  def novo_item(**atributos)
    described_class.new(cardapio:, categoria: "prato_principal", variante: :padrao, descricao: "Frango grelhado", **atributos)
  end

  it "é válido com cardápio, categoria e descrição" do
    expect(novo_item).to be_valid
  end

  it "aceita item sem variante (ex.: bebida)" do
    expect(novo_item(categoria: "bebida", variante: nil)).to be_valid
  end

  it "recusa variante desconhecida" do
    expect(novo_item(variante: "carnivoro")).not_to be_valid
  end

  it "exige categoria e descrição" do
    expect(novo_item(categoria: "")).not_to be_valid
    expect(novo_item(descricao: "")).not_to be_valid
  end

  it "usa a tabela itens_cardapio" do
    expect(described_class.table_name).to eq("itens_cardapio")
  end

  describe "#prato_principal?" do
    it "só é verdadeiro para a categoria do prato principal" do
      expect(novo_item).to be_prato_principal
      expect(novo_item(categoria: "bebida")).not_to be_prato_principal
    end
  end
end
