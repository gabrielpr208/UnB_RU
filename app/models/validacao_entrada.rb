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
    return recusar("Saldo insuficiente") unless cobrar

    liberar
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

  def cobrar
    Estudante.transaction do
      next false unless estudante.debitar(preco)

      @catraca.acessos.create!(estudante:, data_hora: @agora, valor_cobrado: preco)
    end
  end

  def liberar
    @liberada = true
    @mensagem = "Entrada liberada"
    true
  end

  def recusar(mensagem)
    @mensagem = mensagem
    false
  end
end
