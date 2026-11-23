# Monta um "Pix copia e cola" no layout do BR Code do Banco Central, só para ilustrar a recarga.
#
# A chave Pix é um UUID sorteado na hora, que não está cadastrado em banco nenhum: o código tem a
# aparência de um Pix de verdade, mas um app de banco não consegue pagar para ele.
module CodigoPix
  NOME_DO_RECEBEDOR = "RU UNB DEMONSTRACAO".freeze
  CIDADE_DO_RECEBEDOR = "BRASILIA".freeze

  module_function

  def gerar(valor:, chave: SecureRandom.uuid, identificador: SecureRandom.alphanumeric(25))
    conta = campo("00", "br.gov.bcb.pix") + campo("01", chave)

    payload = campo("00", "01") +
              campo("26", conta) +
              campo("52", "0000") +
              campo("53", "986") +
              campo("54", format("%.2f", valor)) +
              campo("58", "BR") +
              campo("59", NOME_DO_RECEBEDOR) +
              campo("60", CIDADE_DO_RECEBEDOR) +
              campo("62", campo("05", identificador)) +
              "6304"

    payload + crc16(payload)
  end

  # Cada campo do BR Code é: ID (2 dígitos) + tamanho do conteúdo (2 dígitos) + conteúdo.
  def campo(id, conteudo)
    "#{id}#{conteudo.length.to_s.rjust(2, "0")}#{conteudo}"
  end

  # CRC16-CCITT (polinômio 0x1021, valor inicial 0xFFFF), usado como dígito verificador do BR Code.
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
