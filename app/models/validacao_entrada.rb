# Validação da entrada de um estudante numa catraca: confere a matrícula, o horário de refeição e o saldo, e
# cobra a refeição quando está tudo certo.
class ValidacaoEntrada
  # Mensagem do resultado, mostrada ao funcionário depois de #processar (ex.: <tt>"Saldo insuficiente"</tt>).
  attr_reader :mensagem

  # Prepara a validação de uma entrada.
  #
  # Argumentos::
  #   - +catraca+: Catraca em que o estudante está entrando.
  #   - +identificacao+: matrícula digitada (espaços nas pontas são ignorados).
  #   - +agora+: horário da entrada (padrão: +Time.current+).
  # Retorno:: um ValidacaoEntrada ainda não processado.
  # Efeitos colaterais:: nenhum.
  def initialize(catraca:, identificacao:, agora: Time.current)
    @catraca = catraca
    @identificacao = identificacao.to_s.strip
    @agora = agora
  end

  # Valida a entrada e, se ela for permitida, cobra a refeição e registra o acesso.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - +true+ se a entrada foi liberada;
  #   - +false+ se a matrícula não existe, se está fora do horário de refeição ou se falta saldo.
  #   Nos dois casos, o motivo fica em #mensagem.
  # Efeitos colaterais::
  #   quando a entrada é liberada, desconta o preço do saldo do estudante e cria um Acesso na catraca,
  #   numa mesma transação.
  def processar
    return recusar("Identificação inválida") unless estudante
    return recusar("Fora do horário de refeição") unless preco
    return recusar("Saldo insuficiente") unless cobrar

    liberar
  end

  # Diz se a entrada foi liberada por #processar.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+ se a entrada foi liberada; +false+ se foi recusada ou ainda não foi processada.
  # Efeitos colaterais:: nenhum.
  def liberada?
    @liberada == true
  end

  private

  # Estudante dono da matrícula digitada.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Estudante encontrado, ou +nil+ se a matrícula não existe.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def estudante
    @estudante ||= Estudante.find_by(matricula: @identificacao)
  end

  # Preço da refeição servida no horário da entrada (ver PrecoRefeicao.vigente).
  #
  # Argumentos:: nenhum.
  # Retorno:: +BigDecimal+ com o preço, ou +nil+ fora do horário de refeição.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def preco
    @preco ||= PrecoRefeicao.vigente(@agora)
  end

  # Cobra a refeição do estudante e registra o acesso na catraca.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   - o Acesso criado, se a cobrança deu certo;
  #   - +false+ se o saldo é insuficiente.
  # Efeitos colaterais::
  #   numa mesma transação, desconta o preço do saldo do estudante e cria um Acesso no banco.
  def cobrar
    Estudante.transaction do
      next false unless estudante.debitar(preco)

      @catraca.acessos.create!(estudante:, data_hora: @agora, valor_cobrado: preco)
    end
  end

  # Marca a entrada como liberada.
  #
  # Argumentos:: nenhum.
  # Retorno:: +true+.
  # Efeitos colaterais:: define #mensagem como <tt>"Entrada liberada"</tt> e faz #liberada? devolver +true+.
  def liberar
    @liberada = true
    @mensagem = "Entrada liberada"
    true
  end

  # Marca a entrada como recusada.
  #
  # Argumentos::
  #   - +mensagem+: motivo da recusa.
  # Retorno:: +false+.
  # Efeitos colaterais:: define #mensagem com o motivo da recusa.
  def recusar(mensagem)
    @mensagem = mensagem
    false
  end
end
