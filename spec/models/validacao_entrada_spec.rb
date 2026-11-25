require "rails_helper"

RSpec.describe ValidacaoEntrada, type: :model do
  let(:catraca) { catraca_padrao }
  let(:almoco) { Time.zone.local(2026, 10, 16, 12) }
  let!(:estudante) { criar_estudante(matricula: "231012345").tap { |e| e.update!(saldo: 4.50) } }

  before { PrecoRefeicao.create!(refeicao: "almoco", valor: 4.50) }

  def validar(identificacao, agora: almoco)
    described_class.new(catraca:, identificacao:, agora:).tap(&:processar)
  end

  it "libera a entrada, debita o saldo e registra o acesso" do
    validacao = validar("231012345")

    expect(validacao).to be_liberada
    expect(validacao.mensagem).to eq("Entrada liberada")
    expect(estudante.reload.saldo).to eq(0)
    expect(catraca.acessos.sole).to have_attributes(estudante:, valor_cobrado: 4.50, data_hora: almoco)
  end

  it "recusa a entrada com saldo insuficiente" do
    estudante.update!(saldo: 4.49)
    validacao = validar("231012345")

    expect(validacao).not_to be_liberada
    expect(validacao.mensagem).to eq("Saldo insuficiente")
    expect(estudante.reload.saldo).to eq(4.49)
    expect(catraca.acessos).to be_empty
  end

  it "recusa a entrada com identificação inválida" do
    [ "23101234", "231A12345", "", "200000000" ].each do |id|
      validacao = validar(id)

      expect(validacao).not_to be_liberada
      expect(validacao.mensagem).to eq("Identificação inválida")
      expect(estudante.reload.saldo).to eq(4.50)
      expect(catraca.acessos).to be_empty
    end
  end

  it "devolve true quando libera e false quando recusa" do
    expect(described_class.new(catraca:, identificacao: "231012345", agora: almoco).processar).to be(true)
    expect(described_class.new(catraca:, identificacao: "231012345", agora: almoco).processar).to be(false)
  end

  it "confere o saldo atual no banco, e não o que estava carregado na memória" do
    desatualizado = Estudante.find(estudante.id)
    estudante.update!(saldo: 0)
    allow(Estudante).to receive(:find_by).with(matricula: "231012345").and_return(desatualizado)

    validacao = validar("231012345")

    expect(validacao.mensagem).to eq("Saldo insuficiente")
    expect(estudante.reload.saldo).to eq(0)
    expect(catraca.acessos).to be_empty
  end

  it "não desconta o saldo se o acesso não puder ser registrado" do
    allow(catraca.acessos).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect { validar("231012345") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(estudante.reload.saldo).to eq(4.50)
  end

  it "recusa a entrada fora do horário" do
    validacao = validar("231012345", agora: Time.zone.local(2026, 10, 16, 22, 1))

    expect(validacao).not_to be_liberada
    expect(validacao.mensagem).to eq("Fora do horário de refeição")
    expect(estudante.reload.saldo).to eq(4.50)
    expect(catraca.acessos).to be_empty
  end
end
