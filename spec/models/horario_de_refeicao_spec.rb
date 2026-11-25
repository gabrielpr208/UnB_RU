require "rails_helper"

RSpec.describe HorarioDeRefeicao do
  def as(horario, segundos: 0)
    hora, minuto = horario.split(":").map(&:to_i)
    Time.zone.local(2026, 10, 16, hora, minuto, segundos)
  end

  describe ".em_andamento" do
    {
      "06:00" => "cafe_da_manha",
      "09:00" => "cafe_da_manha",
      "10:59" => "cafe_da_manha",
      "11:00" => "almoco",
      "14:00" => "almoco",
      "16:59" => "almoco",
      "17:00" => "jantar",
      "20:00" => "jantar",
      "22:00" => "jantar"
    }.each do |horario, refeicao|
      it "às #{horario} a refeição é #{refeicao} (início e fim inclusivos)" do
        expect(described_class.em_andamento(as(horario)).refeicao).to eq(refeicao)
      end
    end

    %w[ 22:01 05:59 ].each do |horario|
      it "às #{horario} não há refeição" do
        expect(described_class.em_andamento(as(horario))).to be_nil
      end
    end

    it "ignora os segundos: 10:59:59 ainda é café da manhã" do
      expect(described_class.em_andamento(as("10:59", segundos: 59)).refeicao).to eq("cafe_da_manha")
    end

    it "usa o horário atual quando nenhum é informado" do
      travel_to as("12:00") do
        expect(described_class.em_andamento.refeicao).to eq("almoco")
      end
    end
  end

  describe ".proxima" do
    {
      "05:59" => "Café da manhã às 06:00",
      "22:01" => "Café da manhã de amanhã às 06:00",
      "00:00" => "Café da manhã às 06:00"
    }.each do |horario, descricao|
      it "às #{horario} a próxima refeição é \"#{descricao}\"" do
        expect(described_class.proxima(as(horario)).descricao).to eq(descricao)
      end
    end

    it "marca como de amanhã só depois do jantar" do
      expect(described_class.proxima(as("22:01")).amanha).to be(true)
      expect(described_class.proxima(as("05:00")).amanha).to be(false)
    end
  end
end
