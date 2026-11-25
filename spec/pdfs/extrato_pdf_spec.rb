require "rails_helper"

RSpec.describe ExtratoPdf do
  let(:estudante) { criar_estudante }

  def texto_do_pdf(**filtros)
    extrato = Extrato.new(**filtros).tap { |e| e.estudante = estudante }
    PDF::Reader.new(StringIO.new(described_class.new(extrato).render)).pages.map(&:text).join("\n")
  end

  # Texto depois de "Movimentações:" no PDF, até o subtítulo da tabela. O texto longo quebra de linha no PDF.
  def descricao_dos_filtros(**filtros)
    texto_do_pdf(**filtros)[/Movimentações: (.+?)\n\s*Movimentações\b/m, 1].squish
  end

  describe "conteúdo" do
    before do
      estudante.creditar!(65.5)
      estudante.recargas.create!(metodo: :pix, valor: 50, status: :confirmada, confirmada_em: Time.zone.local(2026, 10, 12, 10))
      estudante.recargas.create!(metodo: :cartao, valor: 20, status: :confirmada,
                                 confirmada_em: Time.zone.local(2026, 10, 10, 11, 30))
      estudante.acessos.create!(valor_cobrado: 4.5, data_hora: Time.zone.local(2026, 10, 11, 12, 5), catraca: catraca_padrao)
    end

    # Linhas entre o título e o rodapé, sem os espaços que o PDF usa para alinhar as colunas da tabela.
    def linhas_do_conteudo
      linhas = texto_do_pdf.lines.map(&:squish).reject(&:empty?)
      linhas[(linhas.index("Extrato e histórico de refeições") + 1)...linhas.index { |l| l.start_with?("Gerado em") }]
    end

    it "mostra os dados do estudante, a tabela de movimentações e o resumo, nesta ordem" do
      expect(linhas_do_conteudo).to eq([
        "Estudante: Estudante Existente",
        "Matrícula: 231012345",
        "Saldo atual: R$ 65,50",
        "Movimentações: todas",
        "Movimentações",
        "MOVIMENTAÇÃO DATA E HORA VALOR",
        "Recarga · PIX 12/10/2026 10:00 +R$ 50,00",
        "Refeição 11/10/2026 12:05 -R$ 4,50",
        "Recarga · Cartão de crédito 10/10/2026 11:30 +R$ 20,00",
        "Resumo",
        "Entradas: +R$ 70,00",
        "Saídas: -R$ 4,50",
        "Quantidade de movimentações: 3"
      ])
    end
  end

  describe "descrição dos filtros" do
    it "sem filtros, diz que são todas" do
      expect(descricao_dos_filtros).to eq("todas")
    end

    it "lista cada filtro aplicado, na ordem: tipo, período e faixa de valor" do
      filtros = { tipo: "refeicoes", data_inicial: "2026-10-01", data_final: "2026-10-31",
                  valor_minimo: "4,00", valor_maximo: "1.000,00" }

      expect(descricao_dos_filtros(**filtros)).to eq(
        "filtradas (só refeições, a partir de 01/10/2026, até 31/10/2026, " \
        "valor mínimo de R$ 4,00, valor máximo de R$ 1.000,00)"
      )
    end

    {
      { tipo: "recargas" } => "filtradas (só recargas)",
      { data_inicial: "2026-10-01" } => "filtradas (a partir de 01/10/2026)",
      { data_final: "2026-10-31" } => "filtradas (até 31/10/2026)",
      { valor_minimo: "4,50" } => "filtradas (valor mínimo de R$ 4,50)",
      { valor_maximo: "20" } => "filtradas (valor máximo de R$ 20,00)"
    }.each do |filtros, esperado|
      it "com só #{filtros.keys.first}, mostra \"#{esperado}\"" do
        expect(descricao_dos_filtros(**filtros)).to eq(esperado)
      end
    end
  end
end
