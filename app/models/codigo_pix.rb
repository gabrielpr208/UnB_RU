# Monta um "Pix copia e cola" no layout do BR Code do Banco Central, só para ilustrar a recarga.
#
# A chave Pix é um UUID sorteado na hora, que não está cadastrado em banco nenhum: o código tem a
# aparência de um Pix de verdade, mas um app de banco não consegue pagar para ele.
#
# As funções são chamadas direto no módulo (ex.: <tt>CodigoPix.gerar(valor: 20)</tt>).
module CodigoPix
  # Nome do recebedor que aparece no app do banco ao ler o código.
  NOME_DO_RECEBEDOR = "RU UNB DEMONSTRACAO".freeze
  # Cidade do recebedor que aparece no app do banco ao ler o código.
  CIDADE_DO_RECEBEDOR = "BRASILIA".freeze

  module_function

  # Gera o código "Pix copia e cola" de uma recarga.
  #
  # Argumentos::
  #   - +valor+: valor da recarga em reais (ex.: +20+ ou <tt>BigDecimal("20.5")</tt>).
  #   - +chave+: chave Pix do recebedor (padrão: um UUID aleatório).
  #   - +identificador+: identificador da transação (padrão: 25 caracteres alfanuméricos aleatórios).
  # Retorno:: +String+ com o payload do BR Code, terminado pelo CRC16.
  # Efeitos colaterais:: nenhum.
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

  # Monta vários campos do BR Code em sequência, na ordem em que foram passados.
  #
  # Argumentos::
  #   - +pares+: +Hash+ de ID do campo e conteúdo (ex.: <tt>{ "58" => "BR", "60" => "BRASILIA" }</tt>).
  # Retorno:: +String+ com os campos montados um após o outro (ver #campo).
  # Efeitos colaterais:: nenhum.
  def campos(pares)
    pares.map { |id, conteudo| campo(id, conteudo) }.join
  end

  # Monta um campo do BR Code: ID (2 dígitos) + tamanho do conteúdo (2 dígitos) + conteúdo.
  #
  # Argumentos::
  #   - +id+: identificador do campo (ex.: <tt>"54"</tt> para o valor).
  #   - +conteudo+: texto do campo.
  # Retorno:: +String+ com o campo montado (ex.: <tt>campo("58", "BR")</tt> devolve <tt>"5802BR"</tt>).
  # Efeitos colaterais:: nenhum.
  def campo(id, conteudo)
    "#{id}#{conteudo.length.to_s.rjust(2, "0")}#{conteudo}"
  end

  # Calcula o CRC16-CCITT (polinômio 0x1021, valor inicial 0xFFFF), usado como dígito verificador do BR Code.
  #
  # Argumentos::
  #   - +texto+: payload do BR Code até o ID e o tamanho do campo do CRC (<tt>"6304"</tt>).
  # Retorno:: +String+ com o CRC em 4 dígitos hexadecimais maiúsculos.
  # Efeitos colaterais:: nenhum.
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
