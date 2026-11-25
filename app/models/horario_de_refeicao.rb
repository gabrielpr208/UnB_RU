# Horários das refeições dos restaurantes universitários. Início e fim são inclusivos e a comparação é
# feita por minuto: 10:59 ainda é café da manhã, 11:00 já não é.
class HorarioDeRefeicao
  # Horário de uma refeição. +inicio+ e +fim+ são minutos contados a partir da meia-noite (ex.: 420 = 07:00).
  class Janela < Data.define(:refeicao, :nome, :inicio, :fim)
    # Horário de início da refeição no formato HH:MM.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ com o horário (ex.: <tt>"06:00"</tt>).
    # Efeitos colaterais:: nenhum.
    def horario_de_inicio
      format("%02d:%02d", *inicio.divmod(60))
    end
  end

  # A próxima refeição e se ela é a de amanhã (passou da última refeição do dia).
  class Proxima < Data.define(:janela, :amanha)
    # Texto que avisa quando será a próxima refeição.
    #
    # Argumentos:: nenhum.
    # Retorno:: +String+ como <tt>"Almoço às 11:00"</tt> ou <tt>"Café da manhã de amanhã às 06:00"</tt>.
    # Efeitos colaterais:: nenhum.
    def descricao
      "#{janela.nome} #{"de amanhã " if amanha}às #{janela.horario_de_inicio}"
    end
  end

  # As refeições do dia, em ordem de horário.
  JANELAS = [
    Janela.new(refeicao: "cafe_da_manha", nome: "Café da manhã", inicio: 6 * 60, fim: 10 * 60 + 59),
    Janela.new(refeicao: "almoco", nome: "Almoço", inicio: 11 * 60, fim: 16 * 60 + 59),
    Janela.new(refeicao: "jantar", nome: "Jantar", inicio: 17 * 60, fim: 22 * 60)
  ].freeze

  # Refeição sendo servida num horário.
  #
  # Argumentos::
  #   - +agora+: horário consultado (padrão: +Time.current+).
  # Retorno::
  #   - a Janela da refeição em andamento;
  #   - +nil+ fora do horário de refeição.
  # Efeitos colaterais:: nenhum.
  def self.em_andamento(agora = Time.current)
    minuto = minuto_do_dia(agora)
    JANELAS.find { |janela| minuto.between?(janela.inicio, janela.fim) }
  end

  # Próxima refeição a começar depois de um horário. Depois do jantar, é o café da manhã do dia seguinte.
  #
  # Argumentos::
  #   - +agora+: horário consultado (padrão: +Time.current+).
  # Retorno:: um Proxima com a Janela da próxima refeição e se ela é a de amanhã.
  # Efeitos colaterais:: nenhum.
  def self.proxima(agora = Time.current)
    minuto = minuto_do_dia(agora)
    janela = JANELAS.find { |candidata| candidata.inicio > minuto }

    janela ? Proxima.new(janela:, amanha: false) : Proxima.new(janela: JANELAS.first, amanha: true)
  end

  # Converte um horário em minutos contados a partir da meia-noite, ignorando os segundos.
  #
  # Argumentos::
  #   - +horario+: um +Time+ (ou +ActiveSupport::TimeWithZone+).
  # Retorno:: +Integer+ de 0 a 1439 (ex.: 690 para 11:30).
  # Efeitos colaterais:: nenhum.
  def self.minuto_do_dia(horario)
    horario.hour * 60 + horario.min
  end
  private_class_method :minuto_do_dia
end
