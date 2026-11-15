module CatracaHelpers
  def catraca_padrao
    restaurante = Restaurante.find_or_create_by!(nome: "RU Darcy Ribeiro") { |r| r.campus = "Darcy Ribeiro" }
    restaurante.catracas.find_or_create_by!(identificador: "01")
  end
end

RSpec.configure do |config|
  config.include CatracaHelpers
end
