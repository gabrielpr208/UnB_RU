require "rails_helper"

RSpec.describe Extrato, type: :model do
  let(:estudante) { criar_estudante }

  def em(texto)
    Time.zone.strptime(texto, "%d/%m/%Y %H:%M")
  end

  def recarga(valor, quando, metodo: :cartao, de: estudante)
    de.recargas.create!(metodo:, valor:, status: :confirmada, confirmada_em: em(quando))
  end

  def refeicao(valor, quando, de: estudante)
    de.acessos.create!(valor_cobrado: valor, data_hora: em(quando))
  end

  def extrato(**filtros)
    described_class.new(**filtros).tap { |e| e.estudante = estudante }
  end

  # [tipo, valor com sinal, "dd/mm hh:mm"] de cada movimentação, na ordem do extrato.
  def linhas(**filtros)
    extrato(**filtros).movimentacoes.map { |m| [ m.tipo, m.valor, m.data_hora.strftime("%d/%m %H:%M") ] }
  end

  context "com movimentações" do
    before do
      refeicao(4.5, "11/10/2026 12:05")
      refeicao(4.5, "10/10/2026 12:00")
      recarga(20, "10/10/2026 11:30")
      recarga(50, "12/10/2026 10:00", metodo: :pix)
      refeicao(13, "12/10/2026 19:00")
    end

    it "lista recargas como entradas e refeições como saídas, da mais recente para a mais antiga" do
      expect(linhas).to eq([
        [ :refeicao, -13, "12/10 19:00" ],
        [ :recarga, 50, "12/10 10:00" ],
        [ :refeicao, -4.5, "11/10 12:05" ],
        [ :refeicao, -4.5, "10/10 12:00" ],
        [ :recarga, 20, "10/10 11:30" ]
      ])
    end

    it "mostra a forma de pagamento das recargas" do
      detalhes = extrato.movimentacoes.to_h { |m| [ m.data_hora.strftime("%d/%m %H:%M"), m.detalhe ] }

      expect(detalhes).to include("12/10 10:00" => "PIX", "10/10 11:30" => "Cartão de crédito", "11/10 12:05" => nil)
    end

    it "deixa de fora as recargas PIX que não foram confirmadas" do
      estudante.recargas.create!(metodo: :pix, valor: 30)
      estudante.recargas.create!(metodo: :pix, valor: 40, status: :expirada)

      expect(linhas.map(&:second)).not_to include(30, 40)
      expect(linhas.size).to eq(5)
    end

    it "não mostra as movimentações de outro estudante" do
      outro = criar_estudante(matricula: "200000000", email: "outro@aluno.unb.br")
      recarga(99, "12/10/2026 09:00", de: outro)
      refeicao(9.99, "12/10/2026 12:00", de: outro)

      expect(linhas.map(&:second)).not_to include(99, -9.99)
    end

    it "soma as entradas e as saídas" do
      expect(extrato.entradas).to eq(70)
      expect(extrato.saidas).to eq(-22)
    end

    describe "filtro por tipo" do
      it "mostra só as recargas" do
        expect(linhas(tipo: "recargas")).to eq([ [ :recarga, 50, "12/10 10:00" ], [ :recarga, 20, "10/10 11:30" ] ])
      end

      it "mostra só as refeições" do
        expect(linhas(tipo: "refeicoes").map(&:first)).to eq(%i[ refeicao refeicao refeicao ])
      end

      it "mostra tudo com um tipo desconhecido" do
        filtrado = extrato(tipo: "boleto")

        expect(filtrado.tipo).to eq("todos")
        expect(filtrado.movimentacoes.size).to eq(5)
      end

      it "soma só o que foi filtrado" do
        so_refeicoes = extrato(tipo: "refeicoes")

        expect(so_refeicoes.entradas).to eq(0)
        expect(so_refeicoes.saidas).to eq(-22)
      end
    end

    describe "filtro por período" do
      it "inclui a data inicial e a data final inteiras" do
        expect(linhas(data_inicial: "2026-10-11", data_final: "2026-10-12").map(&:third))
          .to eq([ "12/10 19:00", "12/10 10:00", "11/10 12:05" ])
      end

      it "aceita um único dia" do
        expect(linhas(data_inicial: "2026-10-11", data_final: "2026-10-11").map(&:third)).to eq([ "11/10 12:05" ])
      end

      it "aceita só a data inicial" do
        expect(linhas(data_inicial: "2026-10-12").map(&:third)).to eq([ "12/10 19:00", "12/10 10:00" ])
      end

      it "aceita só a data final" do
        expect(linhas(data_final: "2026-10-10").map(&:third)).to eq([ "10/10 12:00", "10/10 11:30" ])
      end

      it "usa o fuso de Brasília para decidir o dia" do
        # 23:30 em Brasília já é dia 13 em UTC.
        refeicao(4.5, "12/10/2026 23:30")
        refeicao(4.5, "13/10/2026 00:00")

        expect(linhas(data_final: "2026-10-12").map(&:third)).to include("12/10 23:30")
        expect(linhas(data_final: "2026-10-12").map(&:third)).not_to include("13/10 00:00")
      end
    end

    describe "filtro por faixa de valor" do
      it "compara o valor sem o sinal" do
        expect(linhas(valor_minimo: "4,00", valor_maximo: "5,00").map(&:second)).to eq([ -4.5, -4.5 ])
      end

      it "inclui os limites" do
        expect(linhas(valor_minimo: "13", valor_maximo: "20").map(&:second)).to eq([ -13, 20 ])
      end

      it "aceita só o valor mínimo" do
        expect(linhas(valor_minimo: "20,00").map(&:second)).to eq([ 50, 20 ])
      end

      it "aceita só o valor máximo" do
        expect(linhas(valor_maximo: "4,50").map(&:second)).to eq([ -4.5, -4.5 ])
      end

      it "aceita valores no formato brasileiro com milhar" do
        expect(linhas(valor_maximo: "1.000,00").size).to eq(5)
      end
    end

    it "combina os filtros" do
      expect(linhas(tipo: "refeicoes", data_inicial: "2026-10-11", valor_maximo: "10"))
        .to eq([ [ :refeicao, -4.5, "11/10 12:05" ] ])
    end
  end

  it "fica vazio para quem não tem movimentações" do
    expect(extrato.movimentacoes).to be_empty
    expect(extrato.entradas).to eq(0)
    expect(extrato.saidas).to eq(0)
  end

  describe "#filtrado?" do
    it "é falso sem filtros" do
      expect(extrato).not_to be_filtrado
      expect(extrato(tipo: "todos", data_inicial: "", valor_minimo: "")).not_to be_filtrado
    end

    [
      { tipo: "recargas" },
      { data_inicial: "2026-10-11" },
      { data_final: "2026-10-11" },
      { valor_minimo: "1" },
      { valor_maximo: "abc" }
    ].each do |filtro|
      it "é verdadeiro com #{filtro}" do
        expect(extrato(**filtro)).to be_filtrado
      end
    end
  end

  describe "validação" do
    it "aceita filtros vazios" do
      expect(extrato).to be_valid
    end

    it "recusa uma data final anterior à data inicial" do
      filtro = extrato(data_inicial: "2026-10-12", data_final: "2026-10-11")

      expect(filtro).not_to be_valid
      expect(filtro.errors[:data_final]).to eq([ "A data final não pode ser anterior à data inicial" ])
    end

    it "recusa um valor máximo menor que o mínimo" do
      filtro = extrato(valor_minimo: "20,00", valor_maximo: "5,00")

      expect(filtro).not_to be_valid
      expect(filtro.errors[:valor_maximo]).to eq([ "O valor máximo não pode ser menor que o valor mínimo" ])
    end

    it "aceita valor mínimo igual ao máximo" do
      expect(extrato(valor_minimo: "4,50", valor_maximo: "4,50")).to be_valid
    end

    %w[ abc -5 4,555 ].each do |texto|
      it "recusa o valor #{texto.inspect}" do
        filtro = extrato(valor_minimo: texto, valor_maximo: texto)

        expect(filtro).not_to be_valid
        expect(filtro.errors[:valor_minimo]).to eq([ "Informe um valor numérico válido" ])
        expect(filtro.errors[:valor_maximo]).to eq([ "Informe um valor numérico válido" ])
      end
    end
  end
end
