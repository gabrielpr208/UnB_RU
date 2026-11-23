require "rails_helper"

RSpec.describe ValorMonetario do
  subject(:tipo) { described_class.new }

  describe "#cast" do
    {
      "20" => "20",
      "20,5" => "20.5",
      "20,50" => "20.5",
      "1000,00" => "1000",
      "1.000,00" => "1000",
      "1.000" => "1000",
      "12.345,67" => "12345.67",
      "20.50" => "20.5",
      "R$ 15,90" => "15.9",
      "  7,00  " => "7"
    }.each do |texto, esperado|
      it "entende #{texto.inspect} como #{esperado}" do
        expect(tipo.cast(texto)).to eq(BigDecimal(esperado))
      end
    end

    [ "abc", "20,505", "-5", "1,000.00", "20,", "10 reais" ].each do |texto|
      it "devolve nil para #{texto.inspect}" do
        expect(tipo.cast(texto)).to be_nil
      end
    end

    it "devolve nil para texto em branco" do
      expect(tipo.cast("  ")).to be_nil
    end

    it "aceita números" do
      expect(tipo.cast(20)).to eq(BigDecimal("20"))
      expect(tipo.cast(BigDecimal("1.5"))).to eq(BigDecimal("1.5"))
    end

    it "arredonda para centavos" do
      expect(tipo.cast(1.005).to_s).to eq("1.01")
    end
  end

  describe ".formatar" do
    it "escreve o valor em reais no padrão brasileiro" do
      expect(described_class.formatar(1)).to eq("R$ 1,00")
      expect(described_class.formatar(BigDecimal("1000"))).to eq("R$ 1.000,00")
    end
  end
end
