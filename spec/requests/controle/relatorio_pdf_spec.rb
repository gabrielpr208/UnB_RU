require "rails_helper"

RSpec.describe "Relatório Global de Operação em PDF", type: :request do
  let!(:administrador) { criar_funcionario(siape: "7654321", email: "admin@unb.br", administrador: true) }
  let!(:darcy) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:gama) { Restaurante.create!(nome: "RU Gama", campus: "Gama") }
  let!(:fce) { Restaurante.create!(nome: "RU FCE", campus: "Ceilândia") }
  let!(:estudante) { criar_estudante(matricula: "231012345") }

  def acesso(restaurante, quando)
    catraca = restaurante.catracas.find_or_create_by!(identificador: "01")
    Acesso.create!(estudante:, catraca:, valor_cobrado: 4.5, data_hora: quando)
  end

  def texto_do_pdf
    PDF::Reader.new(StringIO.new(response.body)).pages.map(&:text).join("\n")
  end

  it "pede login a quem não está logado" do
    get controle_relatorio_pdf_path

    expect(response).to redirect_to(login_controle_path)
  end

  it "recusa o funcionário que não é administrador, sem gerar o documento" do
    entrar_como_funcionario(criar_funcionario(siape: "1234567"))
    get controle_relatorio_pdf_path

    expect(response).to redirect_to(controle_path)
    expect(flash[:alert]).to eq("Acesso restrito a administrador geral")
  end

  it "mantém a mensagem padrão nas outras telas de administrador" do
    entrar_como_funcionario(criar_funcionario(siape: "1234567"))
    get controle_relatorio_path

    expect(flash[:alert]).to eq("Acesso permitido apenas para administradores")
  end

  context "como administrador" do
    before do
      entrar_como_funcionario(administrador)
      acesso(gama, Time.zone.local(2026, 10, 15, 12, 5))
      acesso(darcy, Time.zone.local(2026, 10, 16, 12, 30))
      acesso(darcy, Time.zone.local(2026, 10, 14, 11, 50))
    end

    it "baixa o PDF com o nome e a data" do
      travel_to Time.zone.local(2026, 11, 15, 9) do
        get controle_relatorio_pdf_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/pdf")
      expect(response.headers["Content-Disposition"]).to include("relatorio-global-2026-11-15.pdf")
    end

    it "traz os totais de todos os restaurantes, inclusive sem acessos, e o total geral" do
      get controle_relatorio_pdf_path
      texto = texto_do_pdf

      expect(texto).to include("Relatório Global de Operação")
      expect(texto).to match(/RU Darcy Ribeiro\s+2/)
      expect(texto).to match(/RU Gama\s+1/)
      expect(texto).to match(/RU FCE\s+0/)
      expect(texto).to match(/Total geral\s+3/)
    end

    it "lista os acessos do mais recente para o mais antigo, ignorando os filtros da tela" do
      get controle_relatorio_pdf_path(restaurante_id: gama.id)
      texto = texto_do_pdf

      posicoes = [ "16/10/2026 12:30", "15/10/2026 12:05", "14/10/2026 11:50" ].map { |data| texto.index(data) }
      expect(posicoes).to all(be_present)
      expect(posicoes).to eq(posicoes.sort)
    end

    it "gera o PDF mesmo sem acessos, com os totais zerados" do
      Acesso.delete_all

      get controle_relatorio_pdf_path

      expect(texto_do_pdf).to include("Nenhum acesso registrado.")
      expect(texto_do_pdf).to match(/Total geral\s+0/)
    end
  end
end
