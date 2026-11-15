require "rails_helper"

RSpec.describe "Exportação do extrato em PDF", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345").tap { |e| e.update!(saldo: 25.5) } }

  def recarga(valor, quando, metodo: :cartao)
    estudante.recargas.create!(metodo:, status: :confirmada, valor:, confirmada_em: quando)
  end

  def refeicao(valor, quando)
    estudante.acessos.create!(valor_cobrado: valor, data_hora: quando, catraca: catraca_padrao)
  end

  def texto_do_pdf
    PDF::Reader.new(StringIO.new(response.body)).pages.map(&:text).join("\n")
  end

  context "sem login" do
    it "manda para o login avisando que o extrato exige login" do
      get extrato_pdf_path

      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Você deve estar logado para ter acesso ao extrato")
    end
  end

  context "logado como estudante" do
    before { entrar_como(estudante) }

    context "com movimentações" do
      before do
        recarga(20, Time.zone.local(2026, 10, 10, 11, 30))
        refeicao(4.5, Time.zone.local(2026, 10, 11, 12, 5))
        recarga(10, Time.zone.local(2026, 10, 12, 10, 0), metodo: :pix)
      end

      it "baixa um PDF com o nome da matrícula e a data" do
        travel_to Time.zone.local(2026, 11, 15, 9, 0) do
          get extrato_pdf_path
        end

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("application/pdf")
        expect(response.headers["Content-Disposition"]).to include("attachment")
        expect(response.headers["Content-Disposition"]).to include("extrato-231012345-2026-11-15.pdf")
        expect(response.body).to start_with("%PDF")
      end

      it "traz os dados do estudante, as movimentações da mais recente para a mais antiga e o resumo" do
        get extrato_pdf_path
        texto = texto_do_pdf

        expect(texto).to include("Extrato e histórico de refeições")
        expect(texto).to include("Estudante Existente")
        expect(texto).to include("231012345")
        expect(texto).to include("R$ 25,50")

        posicoes = [ "12/10/2026 10:00", "11/10/2026 12:05", "10/10/2026 11:30" ].map { |data| texto.index(data) }
        expect(posicoes).to all(be_present)
        expect(posicoes).to eq(posicoes.sort)

        expect(texto).to include("Recarga · PIX")
        expect(texto).to include("-R$ 4,50")
        expect(texto).to match(/Entradas:\s*\+R\$ 30,00/)
        expect(texto).to match(/Saídas:\s*-R\$ 4,50/)
      end

      it "respeita os filtros do extrato" do
        get extrato_pdf_path(tipo: "refeicoes")
        texto = texto_do_pdf

        expect(texto).to include("só refeições")
        expect(texto).to include("11/10/2026 12:05")
        expect(texto).not_to include("10/10/2026 11:30")
      end

      it "não inclui movimentações de outros estudantes" do
        outro = criar_estudante(matricula: "231099999", email: "outro@aluno.unb.br")
        outro.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 9, 12, 0), catraca: catraca_padrao)

        get extrato_pdf_path

        expect(texto_do_pdf).not_to include("09/10/2026")
      end

      it "volta para o extrato quando os filtros são inválidos" do
        get extrato_pdf_path(data_inicial: "2026-10-12", data_final: "2026-10-10")

        expect(response).to redirect_to(extrato_path(data_inicial: "2026-10-12", data_final: "2026-10-10"))
        expect(flash[:alert]).to eq("Corrija os filtros do extrato antes de exportar")
      end
    end

    it "sem movimentações, volta para o extrato avisando e não gera o PDF" do
      get extrato_pdf_path

      expect(response).to redirect_to(extrato_path)
      expect(flash[:alert]).to eq("Não há movimentações para exportar")
    end

    it "o botão Exportar PDF do extrato leva os filtros aplicados" do
      get extrato_path(tipo: "recargas", valor_minimo: "5")

      link = Nokogiri::HTML5(response.body).at("a:contains('Exportar PDF')")
      expect(link["href"]).to eq(extrato_pdf_path(tipo: "recargas", valor_minimo: "5"))
    end
  end
end
