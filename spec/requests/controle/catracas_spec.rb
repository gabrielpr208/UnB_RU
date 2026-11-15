require "rails_helper"

RSpec.describe "Gestão de catracas", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }
  let!(:catraca_01) { darcy.catracas.create!(identificador: "01") }
  let!(:catraca_02) { darcy.catracas.create!(identificador: "02") }

  def html
    Nokogiri::HTML5(response.body)
  end

  # [restaurante, catraca, situação] de cada linha da lista.
  def linhas
    html.css("#catracas tbody tr").map { |linha| linha.css("td").first(3).map { |celula| celula.text.strip } }
  end

  def erro_do_campo(id)
    html.at("##{id}_mensagem.campo__erro")&.text&.strip
  end

  describe "acesso" do
    it "pede login a quem não está logado" do
      get controle_catracas_path

      expect(response).to redirect_to(login_controle_path)
    end

    it "não deixa estudante entrar" do
      entrar_como(criar_estudante)
      get controle_catracas_path

      expect(response).to redirect_to(login_controle_path)
      expect(flash[:alert]).to eq("Acesso por estudantes não autorizado")
    end

    it "manda o funcionário que não é administrador de volta para o início, sem alterar nada" do
      entrar_como_funcionario(criar_funcionario(siape: "1234567"))

      get controle_catracas_path
      expect(response).to redirect_to(controle_path)
      expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")

      expect { delete controle_catraca_path(catraca_02) }.not_to change(Catraca, :count)
      expect { post controle_catracas_path, params: { catraca: { restaurante_id: gama.id, identificador: "01" } } }
        .not_to change(Catraca, :count)
    end
  end

  context "como administrador" do
    before { entrar_como_funcionario(administrador) }

    describe "lista" do
      it "mostra as catracas por restaurante e identificador, com a situação de cada uma" do
        gama.catracas.create!(identificador: "01")
        operador = criar_funcionario(siape: "1234567")
        PontoAcesso.abrir!(funcionario: operador, catraca: catraca_02)

        get controle_catracas_path

        expect(response).to have_http_status(:ok)
        expect(linhas).to eq([
          [ "RU Darcy Ribeiro", "01", "Livre" ],
          [ "RU Darcy Ribeiro", "02", "Em uso · Funcionário Existente" ],
          [ "RU Gama", "01", "Livre" ]
        ])
      end

      it "marca só a aba Catracas como ativa" do
        get controle_catracas_path

        expect(html.css(".abas__item--ativa").map(&:text)).to eq([ "Catracas" ])
      end

      it "avisa quando não há catracas" do
        Catraca.delete_all

        get controle_catracas_path

        expect(response.body).to include("Nenhuma catraca cadastrada")
      end
    end

    describe "cadastro" do
      it "mostra o formulário com os restaurantes em ordem alfabética" do
        get new_controle_catraca_path

        expect(response).to have_http_status(:ok)
        expect(html.css("select#catraca_restaurante_id option").map(&:text))
          .to eq([ "Selecione o restaurante", "RU Darcy Ribeiro", "RU Gama" ])
      end

      it "cadastra e volta para a lista com a mensagem de sucesso" do
        expect do
          post controle_catracas_path, params: { catraca: { restaurante_id: gama.id, identificador: "01" } }
        end.to change(gama.catracas, :count).by(1)

        expect(response).to redirect_to(controle_catracas_path)
        expect(flash[:notice]).to eq("Catraca cadastrada com sucesso")
      end

      {
        "" => "O identificador é obrigatório",
        "01" => "Já existe uma catraca com este identificador neste restaurante",
        "123" => "O identificador deve ter 2 dígitos numéricos",
        "1" => "O identificador deve ter 2 dígitos numéricos",
        "AB" => "O identificador deve ter 2 dígitos numéricos"
      }.each do |identificador, mensagem|
        it "com identificador #{identificador.inspect}, não cadastra e mostra \"#{mensagem}\" no campo" do
          expect do
            post controle_catracas_path, params: { catraca: { restaurante_id: darcy.id, identificador: } }
          end.not_to change(Catraca, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(erro_do_campo("catraca_identificador")).to eq(mensagem)
        end
      end

      it "sem restaurante, não cadastra e pede que ele seja selecionado" do
        expect do
          post controle_catracas_path, params: { catraca: { restaurante_id: "", identificador: "03" } }
        end.not_to change(Catraca, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(erro_do_campo("catraca_restaurante_id")).to eq("Selecione um restaurante")
      end
    end

    describe "edição" do
      it "mostra o formulário preenchido" do
        get edit_controle_catraca_path(catraca_01)

        expect(html.at("select#catraca_restaurante_id option[selected]").text).to eq("RU Darcy Ribeiro")
        expect(html.at("input#catraca_identificador")["value"]).to eq("01")
      end

      it "salva e volta para a lista com a mensagem de sucesso" do
        patch controle_catraca_path(catraca_01), params: { catraca: { identificador: "10" } }

        expect(response).to redirect_to(controle_catracas_path)
        expect(flash[:notice]).to eq("Catraca atualizada com sucesso")
        expect(catraca_01.reload.identificador).to eq("10")
      end

      it "não salva identificador repetido no restaurante e mantém o antigo" do
        patch controle_catraca_path(catraca_01), params: { catraca: { identificador: "02" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(erro_do_campo("catraca_identificador")).to eq("Já existe uma catraca com este identificador neste restaurante")
        expect(catraca_01.reload.identificador).to eq("01")
      end
    end

    describe "remoção" do
      it "remove catraca livre" do
        expect { delete controle_catraca_path(catraca_02) }.to change(Catraca, :count).by(-1)

        expect(response).to redirect_to(controle_catracas_path)
        expect(response).to have_http_status(:see_other)
        expect(flash[:notice]).to eq("Catraca removida com sucesso")
      end

      it "não remove catraca em uso e explica o motivo" do
        PontoAcesso.abrir!(funcionario: criar_funcionario(siape: "1234567"), catraca: catraca_01)

        expect { delete controle_catraca_path(catraca_01) }.not_to change(Catraca, :count)

        expect(response).to redirect_to(controle_catracas_path)
        expect(flash[:alert]).to eq("Não é possível remover uma catraca em uso")
      end

      it "responde 404 para catraca inexistente" do
        delete controle_catraca_path(id: 0)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
