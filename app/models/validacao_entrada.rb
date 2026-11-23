class ValidacaoEntrada
  attr_reader :mensagem

  def initialize(catraca:, identificacao:, agora: Time.current)
    @catraca = catraca
    @identificacao = identificacao.to_s.strip
    @agora = agora
  end

  def processar
    return recusar("Identificação inválida") unless estudante
    return recusar("Fora do horário de refeição") unless preco

    Estudante.transaction do
      estudante.lock!

      return recusar("Saldo insuficiente") if estudante.saldo < preco

      estudante.update!(saldo: estudante.saldo - preco)
      @catraca.acessos.create!(estudante:, data_hora: @agora, valor_cobrado: preco)
    end

    @liberada = true
    @mensagem = "Entrada liberada"
    true
  end

  def liberada?
    @liberada == true
  end

  private

  def estudante
    @estudante ||= Estudante.find_by(matricula: @identificacao)
  end

  def preco
    @preco ||= PrecoRefeicao.vigente(@agora)
  end

  def recusar(mensagem)
    @mensagem = mensagem
    false
  end
end
