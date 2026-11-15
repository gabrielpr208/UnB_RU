require 'rails_helper'

RSpec.describe PrecoRefeicao, type: :model do
  def novo_preco(refeicao: "almoco", valor: 4.50)
    described_class.new(refeicao:, valor:)
  end

  it "é válido com refeição conhecida e valor positivo" do
    expect(novo_preco).to be_valid
  end

  it "exige a refeição" do
    expect(novo_preco(refeicao: nil)).not_to be_valid
  end

  it "exige o preço" do
    expect(novo_preco(valor: nil)).not_to be_valid
  end

  it "só aceita as refeições dos horários do restaurante" do
    expect(novo_preco(refeicao: "lanche")).not_to be_valid
  end

  it "não repete o preço de uma mesma refeição" do
    novo_preco.save!

    expect(novo_preco).not_to be_valid
  end

  it "exige valor maior que zero" do
    [ 0, -1 ].each do |valor|
      expect(novo_preco(valor:)).not_to be_valid
    end
  end

  describe ".vigente" do
    def janela(refeicao)
      HorarioDeRefeicao::JANELAS.find { |j| j.refeicao == refeicao }
    end

    before do
      novo_preco(refeicao: "almoco", valor: 4.50).save!
      novo_preco(refeicao: "jantar", valor: 5.00).save!
    end

    it "devolve o preço da refeição sendo servida" do
      { "almoco" => 4.50, "jantar" => 5.00 }.each do |refeicao, valor|
        allow(HorarioDeRefeicao).to receive(:em_andamento).and_return(janela(refeicao))

        expect(described_class.vigente).to eq(valor)
      end
    end

    it "devolve nil fora do horário de refeição" do
      allow(HorarioDeRefeicao).to receive(:em_andamento).and_return(nil)

      expect(described_class.vigente).to be_nil
    end

    it "devolve nil se a refeição atual não tiver preço cadastrado" do
      allow(HorarioDeRefeicao).to receive(:em_andamento).and_return(janela("cafe_da_manha"))

      expect(described_class.vigente).to be_nil
    end
  end
end
