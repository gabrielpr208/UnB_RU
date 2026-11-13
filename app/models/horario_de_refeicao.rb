# Horários das refeições dos restaurantes universitários. Início e fim são inclusivos e a comparação é
# feita por minuto: 09:00 ainda é café da manhã, 09:01 já não é.
class HorarioDeRefeicao
  Janela = Data.define(:refeicao, :nome, :inicio, :fim) do
    def horario_de_inicio
      format("%02d:%02d", *inicio.divmod(60))
    end
  end

  # A próxima refeição e se ela é a de amanhã (passou da última refeição do dia).
  Proxima = Data.define(:janela, :amanha) do
    def descricao
      "#{janela.nome} #{"de amanhã " if amanha}às #{janela.horario_de_inicio}"
    end
  end

  JANELAS = [
    Janela.new(refeicao: "cafe_da_manha", nome: "Café da manhã", inicio: 7 * 60, fim: 9 * 60),
    Janela.new(refeicao: "almoco", nome: "Almoço", inicio: 11 * 60, fim: 14 * 60 + 30),
    Janela.new(refeicao: "jantar", nome: "Jantar", inicio: 17 * 60, fim: 19 * 60 + 30)
  ].freeze

  # Refeição sendo servida em `agora`, ou nil fora do horário.
  def self.em_andamento(agora = Time.current)
    minuto = minuto_do_dia(agora)
    JANELAS.find { |janela| minuto.between?(janela.inicio, janela.fim) }
  end

  def self.proxima(agora = Time.current)
    minuto = minuto_do_dia(agora)
    janela = JANELAS.find { |candidata| candidata.inicio > minuto }

    janela ? Proxima.new(janela:, amanha: false) : Proxima.new(janela: JANELAS.first, amanha: true)
  end

  def self.minuto_do_dia(horario)
    horario.hour * 60 + horario.min
  end
  private_class_method :minuto_do_dia
end
