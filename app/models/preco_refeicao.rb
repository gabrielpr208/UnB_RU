class PrecoRefeicao < ApplicationRecord
  REFEICOES = HorarioDeRefeicao::JANELAS.map(&:refeicao).freeze

  validates :refeicao, presence: true, uniqueness: true, inclusion: { in: REFEICOES }
  validates :valor, numericality: { greater_than: 0 }

  def self.vigente(agora = Time.current)
    janela = HorarioDeRefeicao.em_andamento(agora)
    find_by(refeicao: janela.refeicao)&.valor if janela
  end
end
