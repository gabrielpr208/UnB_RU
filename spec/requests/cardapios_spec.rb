require "rails_helper"

RSpec.describe "Cardápio", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345") }

  def cadastrar(refeicao, padrao:, ovolacto: nil, estrito: nil, data: Date.new(2026, 10, 16))
    cardapio = Cardapio.create!(data:, refeicao:)
    { padrao: padrao, ovolactovegetariano: ovolacto, vegetariano_estrito: estrito }.each do |variante, descricao|
      cardapio.itens.create!(categoria: "prato_principal", variante:, descricao:) if descricao
    end
  end

  def em(horario, data: [ 2026, 10, 16 ], &bloco)
    hora, minuto = horario.split(":").map(&:to_i)
    travel_to(Time.zone.local(*data, hora, minuto), &bloco)
  end

  def html
    Nokogiri::HTML5(response.body)
  end

  # Prato mostrado para cada opção: { "Padrão" => "Frango grelhado", ... }
  def opcoes
    html.css(".lista-dados div").to_h { |linha| [ linha.at("dt").text.strip, linha.at("dd").text.strip ] }
  end

  context "sem login" do
    it "manda para o login pedindo que o estudante entre" do
      get cardapio_path

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
    end

    it "volta para o cardápio depois do login" do
      get cardapio_path
      entrar_como(estudante)

      expect(response).to redirect_to(cardapio_url)
    end
  end

  context "com login" do
    before do
      entrar_como(estudante)
      cadastrar("cafe_da_manha", padrao: "Pão com ovos mexidos", ovolacto: "Pão com ovos mexidos", estrito: "Pão com pasta de grão")
      cadastrar("almoco", padrao: "Frango grelhado", ovolacto: "Omelete de legumes", estrito: "Estrogonofe de grão")
      cadastrar("jantar", padrao: "Carne de panela", ovolacto: "Torta de queijo")
    end

    {
      "07:00" => "Café da manhã",
      "09:00" => "Café da manhã",
      "11:00" => "Almoço",
      "14:30" => "Almoço",
      "17:00" => "Jantar",
      "19:30" => "Jantar"
    }.each do |horario, refeicao|
      it "às #{horario} mostra o cardápio do #{refeicao}" do
        em(horario) { get cardapio_path }

        expect(response).to have_http_status(:ok)
        expect(html.at("h2").text).to include("Cardápio do #{refeicao}")
      end
    end

    it "mostra as três opções da refeição atual" do
      em("12:00") { get cardapio_path }

      expect(opcoes).to eq(
        "Padrão" => "Frango grelhado",
        "Ovolactovegetariano" => "Omelete de legumes",
        "Vegetariano estrito" => "Estrogonofe de grão"
      )
    end

    it "mostra opção não cadastrada como indisponível" do
      em("18:00") { get cardapio_path }

      expect(opcoes).to eq(
        "Padrão" => "Carne de panela",
        "Ovolactovegetariano" => "Torta de queijo",
        "Vegetariano estrito" => "Indisponível nesta refeição"
      )
    end

    {
      "06:59" => "Café da manhã às 07:00",
      "09:01" => "Almoço às 11:00",
      "10:59" => "Almoço às 11:00",
      "14:31" => "Jantar às 17:00",
      "16:59" => "Jantar às 17:00",
      "19:31" => "Café da manhã de amanhã às 07:00"
    }.each do |horario, proxima|
      it "às #{horario} informa que não há refeição e que a próxima é \"#{proxima}\"" do
        em(horario) { get cardapio_path }

        expect(response.body).to include("Nenhuma refeição sendo servida no momento")
        expect(html.at(".alerta__texto strong").text).to eq(proxima)
        expect(html.css(".lista-dados")).to be_empty
      end
    end

    it "avisa quando o cardápio da refeição ainda não foi divulgado" do
      em("12:00", data: [ 2026, 10, 17 ]) { get cardapio_path }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("O cardápio desta refeição ainda não foi divulgado")
    end

    it "não mostra o cardápio de outro dia" do
      cadastrar("almoco", padrao: "Peixe assado", data: Date.new(2026, 10, 15))

      em("12:00") { get cardapio_path }

      expect(opcoes["Padrão"]).to eq("Frango grelhado")
    end

    it "mostra a aba Cardápio como ativa" do
      em("12:00") { get cardapio_path }

      expect(html.at(".abas__item--ativa").text).to eq("Cardápio")
    end
  end
end
