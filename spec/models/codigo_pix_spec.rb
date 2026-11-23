require "rails_helper"

RSpec.describe CodigoPix do
  subject(:codigo) { described_class.gerar(valor: BigDecimal("20"), chave: "chave-ficticia", identificador: "RU123") }

  it "segue o layout do BR Code" do
    expect(codigo).to start_with("000201")
    expect(codigo).to include("0014br.gov.bcb.pix")
    expect(codigo).to include("0114chave-ficticia")
    expect(codigo).to include("5303986") # moeda: 986 = real
    expect(codigo).to include("5802BR")
    expect(codigo).to include("5919RU UNB DEMONSTRACAO")
    expect(codigo).to include("62090505RU123")
  end

  it "monta o código completo, campo por campo, na ordem do BR Code" do
    expect(codigo).to eq(
      "000201" \
      "26360014br.gov.bcb.pix0114chave-ficticia" \
      "52040000" \
      "5303986" \
      "540520.00" \
      "5802BR" \
      "5919RU UNB DEMONSTRACAO" \
      "6008BRASILIA" \
      "62090505RU123" \
      "6304BA86"
    )
  end

  it "calcula o tamanho de cada campo, inclusive dos campos dentro de outros" do
    codigo = described_class.gerar(valor: 4.5, chave: "123e4567-e89b-12d3-a456-426614174000",
                                   identificador: "ABCDEFGHIJKLMNOPQRSTUVWXY")

    expect(codigo).to eq(
      "000201" \
      "26580014br.gov.bcb.pix0136123e4567-e89b-12d3-a456-426614174000" \
      "52040000" \
      "5303986" \
      "54044.50" \
      "5802BR" \
      "5919RU UNB DEMONSTRACAO" \
      "6008BRASILIA" \
      "62290525ABCDEFGHIJKLMNOPQRSTUVWXY" \
      "6304A41B"
    )
  end

  it "traz o valor com duas casas decimais" do
    expect(codigo).to include("540520.00")
  end

  it "termina com o CRC16 do restante do código" do
    expect(codigo[-8..-5]).to eq("6304")
    expect(codigo[-4..]).to eq(described_class.crc16(codigo[0...-4]))
  end

  it "sorteia uma chave e um identificador novos a cada código" do
    expect(described_class.gerar(valor: 20)).not_to eq(described_class.gerar(valor: 20))
  end

  describe ".crc16" do
    it "calcula o CRC16-CCITT usado pelo BR Code" do
      expect(described_class.crc16("123456789")).to eq("29B1")
    end
  end
end
