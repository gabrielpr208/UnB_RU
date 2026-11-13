require "rails_helper"

RSpec.describe "Extrato", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345").tap { |e| e.update!(saldo: 25.5) } }

  def html
    Nokogiri::HTML5(response.body)
  end

  # [tipo, valor, data e hora] como aparecem na tabela do extrato.
  def linhas
    html.css(".extrato tbody tr").map do |linha|
      %w[ .movimentacao__tipo .movimentacao__valor .movimentacao__data ].map { |seletor| linha.at(seletor).text.strip }
    end
  end

  context "sem login" do
    it "manda para o login avisando que o extrato exige login" do
      get extrato_path

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Você deve estar logado para ver o extrato")
    end

    it "volta para o extrato, com os filtros, depois do login" do
      get extrato_path(tipo: "recargas")
      entrar_como(estudante)

      expect(response).to redirect_to(extrato_url(tipo: "recargas"))
    end
  end

  context "com login" do
    before { entrar_como(estudante) }

    context "sem movimentações" do
      it "avisa que ainda não há movimentações" do
        get extrato_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Sem movimentações por enquanto")
        expect(html.at(".extrato")).to be_nil
      end
    end

    context "com movimentações" do
      before do
        estudante.recargas.create!(metodo: :pix, valor: 20, status: :confirmada,
                                   confirmada_em: Time.zone.local(2026, 10, 12, 10))
        estudante.recargas.create!(metodo: :cartao, valor: 1000, status: :confirmada,
                                   confirmada_em: Time.zone.local(2026, 10, 10, 11, 30))
        estudante.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 11, 12, 5))
      end

      it "lista as movimentações da mais recente para a mais antiga" do
        get extrato_path

        expect(linhas).to eq([
          [ "Recarga", "+R$ 20,00", "12/10/2026 10:00" ],
          [ "Refeição", "-R$ 4,50", "11/10/2026 12:05" ],
          [ "Recarga", "+R$ 1.000,00", "10/10/2026 11:30" ]
        ])
      end

      it "mostra o saldo e o resumo das entradas e saídas" do
        get extrato_path

        expect(html.at(".indicador__valor").text).to eq("R$ 25,50")
        expect(html.at(".lista-dados").text.squish).to include("Entradas +R$ 1.020,00", "Saídas -R$ 4,50", "Movimentações 3")
      end

      it "não mostra as movimentações de outro estudante" do
        outro = criar_estudante(matricula: "200000000", email: "outro@aluno.unb.br")
        outro.acessos.create!(valor_cobrado: 9.99, data_hora: Time.zone.local(2026, 10, 12, 12))

        get extrato_path

        expect(response.body).not_to include("9,99")
        expect(linhas.size).to eq(3)
      end

      it "filtra por tipo" do
        get extrato_path(tipo: "refeicoes")

        expect(linhas).to eq([ [ "Refeição", "-R$ 4,50", "11/10/2026 12:05" ] ])
        expect(html.at("input[name=tipo][value=refeicoes]")["checked"]).to be_present
      end

      it "filtra por período e por faixa de valor" do
        get extrato_path(data_inicial: "2026-10-11", data_final: "2026-10-12", valor_minimo: "10", valor_maximo: "")

        expect(linhas).to eq([ [ "Recarga", "+R$ 20,00", "12/10/2026 10:00" ] ])
      end

      it "mantém os filtros preenchidos no formulário" do
        get extrato_path(tipo: "recargas", data_inicial: "2026-10-11", valor_maximo: "50,00")

        expect(html.at("input[name=tipo][value=recargas]")["checked"]).to be_present
        expect(html.at("input[name=data_inicial]")["value"]).to eq("2026-10-11")
        expect(html.at("input[name=valor_maximo]")["value"]).to eq("50,00")
      end

      it "só oferece \"Limpar filtros\" quando há filtro aplicado" do
        get extrato_path
        expect(response.body).not_to include("Limpar filtros")

        get extrato_path(tipo: "recargas")
        expect(html.at_css("a[href='#{extrato_path}']", text: "Limpar filtros")).to be_present
      end

      it "avisa quando nenhuma movimentação passa pelos filtros" do
        get extrato_path(data_inicial: "2026-09-01", data_final: "2026-09-30")

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Nenhuma movimentação encontrada com esses filtros")
        expect(response.body).not_to include("Sem movimentações por enquanto")
      end

      it "mostra o erro e não lista nada com filtros inválidos" do
        get extrato_path(valor_minimo: "abc", data_inicial: "2026-10-12", data_final: "2026-10-11")

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Não foi possível filtrar o extrato")
        expect(response.body).to include("Informe um valor numérico válido")
        expect(response.body).to include("A data final não pode ser anterior à data inicial")
        expect(html.at("input[name=valor_minimo]")["value"]).to eq("abc")
        expect(html.at(".extrato")).to be_nil
      end

      it "ignora um tipo desconhecido e mostra tudo" do
        get extrato_path(tipo: "boleto")

        expect(response).to have_http_status(:ok)
        expect(linhas.size).to eq(3)
      end
    end

    it "destaca a aba \"Extrato\"" do
      get extrato_path

      expect(response.body).to include(%(class="abas__item abas__item--ativa" aria-current="page" href="#{extrato_path}"))
    end

    it "tem um formulário de filtros por GET, sem token e sem parâmetros extras" do
      get extrato_path

      formulario = html.at("form.filtros")
      expect(formulario["method"]).to eq("get")
      expect(formulario.css("[name]").map { |campo| campo["name"] }.uniq)
        .to contain_exactly("tipo", "data_inicial", "data_final", "valor_minimo", "valor_maximo")
    end
  end
end
