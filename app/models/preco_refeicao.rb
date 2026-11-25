# Preço cobrado de cada refeição (café da manhã, almoço e jantar) na entrada do restaurante.
class PrecoRefeicao < ApplicationRecord
  # Refeições que podem ter preço, as mesmas de HorarioDeRefeicao::JANELAS.
  REFEICOES = HorarioDeRefeicao::JANELAS.map(&:refeicao).freeze

  validates :refeicao, presence: true, uniqueness: true, inclusion: { in: REFEICOES }
  validates :valor, numericality: { greater_than: 0 }

  # Preço da refeição servida num horário.
  #
  # Argumentos::
  #   - +agora+: horário consultado (padrão: +Time.current+).
  # Retorno::
  #   - +BigDecimal+ com o preço da refeição em andamento;
  #   - +nil+ fora do horário de refeição ou se a refeição não tem preço cadastrado.
  # Efeitos colaterais:: nenhum (apenas consulta o banco).
  def self.vigente(agora = Time.current)
    janela = HorarioDeRefeicao.em_andamento(agora)
    find_by(refeicao: janela.refeicao)&.valor if janela
  end
end
