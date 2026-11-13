require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#icone" do
    it "gera um SVG decorativo, escondido de leitores de tela" do
      svg = Nokogiri::HTML5.fragment(helper.icone(:usuario, classe: "campo__icone")).at("svg")

      expect(svg["class"]).to eq("icone campo__icone")
      expect(svg["aria-hidden"]).to eq("true")
      expect(svg["viewbox"] || svg["viewBox"]).to eq("0 0 24 24")
    end

    it "falha para um ícone inexistente" do
      expect { helper.icone(:inexistente) }.to raise_error(KeyError)
    end
  end

  describe "#papel_do_funcionario" do
    it "diferencia o administrador do funcionário comum" do
      expect(helper.papel_do_funcionario(Funcionario.new(administrador: false))).to eq("Funcionário")
      expect(helper.papel_do_funcionario(Funcionario.new(administrador: true))).to eq("Administrador")
    end
  end

  describe "#link_de_aba" do
    def aba(caminho_atual, metodo: "GET")
      helper.request.path = caminho_atual
      helper.request.request_method = metodo
      Nokogiri::HTML5.fragment(helper.link_de_aba("Criar conta", "/cadastro")).at("a")
    end

    it "marca a aba da página atual" do
      link = aba("/cadastro")

      expect(link["class"]).to include("abas__item--ativa")
      expect(link["aria-current"]).to eq("page")
    end

    it "continua marcando a aba quando o formulário volta de um POST com erro" do
      expect(aba("/cadastro", metodo: "POST")["class"]).to include("abas__item--ativa")
    end

    it "marca a aba também nas páginas abaixo dela" do
      helper.request.path = "/cadastro/algo"
      link = Nokogiri::HTML5.fragment(helper.link_de_aba("Criar conta", "/cadastro")).at("a")

      expect(link["class"]).to include("abas__item--ativa")
    end

    it "não confunde caminhos que só começam igual" do
      helper.request.path = "/cadastros"
      link = Nokogiri::HTML5.fragment(helper.link_de_aba("Criar conta", "/cadastro")).at("a")

      expect(link["class"]).to eq("abas__item")
    end

    it "não marca as outras abas" do
      link = aba("/login")

      expect(link["class"]).to eq("abas__item")
      expect(link["aria-current"]).to be_nil
    end
  end

  describe "#reais" do
    it "formata valores no padrão brasileiro" do
      expect(helper.reais(BigDecimal("1234.5"))).to eq("R$ 1.234,50")
      expect(helper.reais(0)).to eq("R$ 0,00")
    end
  end

  describe "#reais_com_sinal" do
    it "põe + nas entradas e - nas saídas" do
      expect(helper.reais_com_sinal(BigDecimal("1020"))).to eq("+R$ 1.020,00")
      expect(helper.reais_com_sinal(BigDecimal("-4.5"))).to eq("-R$ 4,50")
    end

    it "não põe sinal no zero" do
      expect(helper.reais_com_sinal(0)).to eq("R$ 0,00")
    end
  end

  describe "#data_e_hora" do
    it "mostra a data e a hora no fuso de Brasília" do
      expect(helper.data_e_hora(Time.utc(2026, 10, 13, 2, 30))).to eq("12/10/2026 23:30")
    end
  end

  describe "#iniciais" do
    it "usa a primeira letra do primeiro e do último nome" do
      expect(helper.iniciais("Maria da Silva Souza")).to eq("MS")
    end

    it "usa uma letra só quando há um nome só" do
      expect(helper.iniciais("maria")).to eq("M")
    end
  end

  describe "#qrcode_svg" do
    it "gera um SVG acessível com o QR Code" do
      svg = Nokogiri::HTML5.fragment(helper.qrcode_svg("conteudo", rotulo: "QR Code do PIX")).at("svg")

      expect(svg["class"]).to eq("qrcode")
      expect(svg["role"]).to eq("img")
      expect(svg["aria-label"]).to eq("QR Code do PIX")
    end
  end

  describe "#tempo_restante" do
    it "mostra minutos e segundos" do
      expect(helper.tempo_restante(60)).to eq("1:00")
      expect(helper.tempo_restante(5)).to eq("0:05")
    end
  end
end
