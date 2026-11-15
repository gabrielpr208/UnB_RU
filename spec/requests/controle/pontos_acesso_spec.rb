require "rails_helper"

RSpec.describe "Configuração do ponto de acesso", type: :request do
  let!(:funcionario) { criar_funcionario(siape: "1234567") }
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:catraca) { darcy.catracas.create!(identificador: "01") }

  def html
    Nokogiri::HTML5(response.body)
  end

  def erro_do_campo(atributo)
    html.at("#configuracao_ponto_acesso_#{atributo}_mensagem.campo__erro")&.text&.strip
  end

  def configurar(restaurante: "RU Darcy Ribeiro", numero_da_catraca: "01")
    post controle_ponto_acesso_path, params: { configuracao_ponto_acesso: { restaurante:, numero_da_catraca: } }
  end

  describe "acesso" do
    it "pede login a quem não está logado, sem abrir ponto de acesso" do
      get controle_ponto_acesso_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Você deve estar logado para acessar esta página")
      expect { configurar }.not_to change(PontoAcesso, :count)
    end

    it "não deixa estudante entrar" do
      entrar_como(criar_estudante)
      get controle_ponto_acesso_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Acesso por estudantes não autorizado")
    end

    it "também atende o administrador" do
      entrar_como_funcionario(criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true))

      expect { configurar }.to change(PontoAcesso, :count).by(1)
      expect(response).to redirect_to(controle_path)
    end
  end

  context "como funcionário" do
    before { entrar_como_funcionario(funcionario) }

    describe "GET /controle/ponto-de-acesso" do
      it "mostra o formulário, sugerindo os restaurantes cadastrados em ordem alfabética" do
        Restaurante.create!(nome: "FUP", campus: "Planaltina")

        get controle_ponto_acesso_path

        expect(response).to have_http_status(:ok)
        expect(html.at("input#configuracao_ponto_acesso_restaurante")["list"]).to eq("lista-restaurantes")
        expect(html.at("input#configuracao_ponto_acesso_numero_da_catraca")).to be_present
        expect(html.css("datalist#lista-restaurantes option").map { |opcao| opcao["value"] })
          .to eq([ "FUP", "RU Darcy Ribeiro" ])
      end

      it "marca a aba Ponto de acesso como ativa" do
        get controle_ponto_acesso_path

        expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Ponto de acesso" ])
      end

      it "mostra o ponto de acesso atual, quando o funcionário já escolheu um" do
        PontoAcesso.abrir!(funcionario:, catraca:)

        get controle_ponto_acesso_path

        expect(html.at(".alerta--info .alerta__titulo").text.squish)
          .to eq("Ponto de acesso atual: RU Darcy Ribeiro · catraca 01")
      end

      it "não mostra ponto de acesso atual antes da primeira escolha" do
        get controle_ponto_acesso_path

        expect(html.at(".alerta--info")).to be_nil
      end
    end

    describe "POST /controle/ponto-de-acesso com dados válidos" do
      it "abre o ponto de acesso e volta para a Aplicação de Controle com a mensagem de sucesso" do
        expect { configurar }.to change(PontoAcesso, :count).by(1)

        expect(response).to redirect_to(controle_path)
        expect(flash[:notice]).to eq("Configuração do ponto de acesso bem-sucedida")
        expect(funcionario.reload.ponto_acesso_atual).to have_attributes(catraca:, encerrado_em: nil)
      end

      it "aceita o nome do restaurante com outras maiúsculas e espaços sobrando" do
        configurar(restaurante: " ru darcy ribeiro ", numero_da_catraca: " 01 ")

        expect(response).to redirect_to(controle_path)
        expect(funcionario.reload.ponto_acesso_atual.catraca).to eq(catraca)
      end

      it "encerra o ponto de acesso anterior quando o funcionário troca de catraca" do
        anterior = PontoAcesso.abrir!(funcionario:, catraca:)
        outra = darcy.catracas.create!(identificador: "02")

        configurar(numero_da_catraca: "02")

        expect(anterior.reload.encerrado_em).to be_present
        expect(funcionario.reload.ponto_acesso_atual.catraca).to eq(outra)
      end
    end

    describe "POST /controle/ponto-de-acesso com dados inválidos" do
      {
        { numero_da_catraca: "123" } => [ :numero_da_catraca, "O número da catraca deve ter 2 dígitos" ],
        { numero_da_catraca: "99" } => [ :numero_da_catraca, "Catraca não encontrada neste restaurante" ],
        { restaurante: "RU Inexistente" } => [ :restaurante, "Restaurante não encontrado" ],
        { restaurante: "" } => [ :restaurante, "Informe o restaurante" ],
        { numero_da_catraca: "" } => [ :numero_da_catraca, "Informe o número da catraca" ]
      }.each do |dados, (atributo, mensagem)|
        it "com #{dados.inspect}, não abre o ponto de acesso, avisa \"Ponto de acesso inválido\" e mostra \"#{mensagem}\" no campo" do
          expect { configurar(**dados) }.not_to change(PontoAcesso, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(html.at(".alerta--erro .alerta__titulo").text).to eq("Ponto de acesso inválido")
          expect(erro_do_campo(atributo)).to eq(mensagem)
        end
      end

      it "mantém o que foi digitado" do
        configurar(restaurante: "RU Inexistente", numero_da_catraca: "07")

        expect(html.at("input#configuracao_ponto_acesso_restaurante")["value"]).to eq("RU Inexistente")
        expect(html.at("input#configuracao_ponto_acesso_numero_da_catraca")["value"]).to eq("07")
      end

      it "mantém o ponto de acesso atual" do
        atual = PontoAcesso.abrir!(funcionario:, catraca:)

        configurar(numero_da_catraca: "99")

        expect(atual.reload.encerrado_em).to be_nil
      end
    end

    describe "POST /controle/ponto-de-acesso sem os dados do formulário" do
      it "responde 400" do
        post controle_ponto_acesso_path, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
