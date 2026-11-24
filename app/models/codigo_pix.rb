module CodigoPix
  NOME_DO_RECEBEDOR = "RU UNB DEMONSTRACAO".freeze
  CIDADE_DO_RECEBEDOR = "BRASILIA".freeze

  module_function

  def gerar(valor:, chave: SecureRandom.uuid, identificador: SecureRandom.alphanumeric(25))
    payload = campos(
      "00" => "01",
      "26" => campos("00" => "br.gov.bcb.pix", "01" => chave),
      "52" => "0000",
      "53" => "986",
      "54" => format("%.2f", valor),
      "58" => "BR",
      "59" => NOME_DO_RECEBEDOR,
      "60" => CIDADE_DO_RECEBEDOR,
      "62" => campos("05" => identificador)
    ) + "6304"

    payload + crc16(payload)
  end

  def campos(pares)
    pares.map { |id, conteudo| campo(id, conteudo) }.join
  end

  def campo(id, conteudo)
    "#{id}#{conteudo.length.to_s.rjust(2, "0")}#{conteudo}"
  end

  def crc16(texto)
    crc = 0xFFFF

    texto.each_byte do |byte|
      crc ^= byte << 8
      8.times { crc = crc.anybits?(0x8000) ? ((crc << 1) ^ 0x1021) : (crc << 1) }
      crc &= 0xFFFF
    end

    format("%04X", crc)
  end
end
