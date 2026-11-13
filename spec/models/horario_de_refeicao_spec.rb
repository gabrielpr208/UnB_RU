require "rails_helper"

RSpec.describe HorarioDeRefeicao do
  def as(horario, segundos: 0)
    hora, minuto = horario.split(":").map(&:to_i)
    Time.zone.local(2026, 10, 16, hora, minuto, segundos)
  end

  describe ".em_andamento" do
    {
      "07:00" => "cafe_da_manha",
      "08:00" => "cafe_da_manha",
      "09:00" => "cafe_da_manha",
      "11:00" => "almoco",
      "14:30" => "almoco",
      "17:00" => "jantar",
      "19:30" => "jantar"
    }.each do |horario, refeicao|
      it "às #{horario} a refeição é #{refeicao} (início e fim inclusivos)" do
        expect(described_class.em_andamento(as(horario)).refeicao).to eq(refeicao)
      end
    end

    %w[ 00:00 06:59 09:01 10:59 14:31 16:59 19:31 23:59 ].each do |horario|
      it "às #{horario} não há refeição" do
        expect(described_class.em_andamento(as(horario))).to be_nil
      end
    end

    it "ignora os segundos: 09:00:59 ainda é café da manhã" do
      expect(described_class.em_andamento(as("09:00", segundos: 59)).refeicao).to eq("cafe_da_manha")
    end

    it "usa o horário atual quando nenhum é informado" do
      travel_to as("12:00") do
        expect(described_class.em_andamento.refeicao).to eq("almoco")
      end
    end
  end

  describe ".proxima" do
    {
      "06:59" => "Café da manhã às 07:00",
      "09:01" => "Almoço às 11:00",
      "10:59" => "Almoço às 11:00",
      "14:31" => "Jantar às 17:00",
      "16:59" => "Jantar às 17:00",
      "19:31" => "Café da manhã de amanhã às 07:00",
      "00:00" => "Café da manhã às 07:00"
    }.each do |horario, descricao|
      it "às #{horario} a próxima refeição é \"#{descricao}\"" do
        expect(described_class.proxima(as(horario)).descricao).to eq(descricao)
      end
    end

    it "marca como de amanhã só depois do jantar" do
      expect(described_class.proxima(as("19:31")).amanha).to be(true)
      expect(described_class.proxima(as("06:00")).amanha).to be(false)
    end
  end
end
