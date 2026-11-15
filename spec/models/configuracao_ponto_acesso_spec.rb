require "rails_helper"

RSpec.describe ConfiguracaoPontoAcesso, type: :model do
  let!(:restaurante) { Restaurante.create!(nome: "RU Darcy Ribeiro", campus: "Darcy Ribeiro") }
  let!(:catraca) { restaurante.catracas.create!(identificador: "01") }
  let(:funcionario) { criar_funcionario }

  def configuracao(restaurante: "RU Darcy Ribeiro", numero_da_catraca: "01")
    described_class.new(restaurante:, numero_da_catraca:).tap { |configuracao| configuracao.funcionario = funcionario }
  end

  it "é válida com restaurante e catraca existentes" do
    expect(configuracao).to be_valid
  end

  it "abre o ponto de acesso do funcionário na catraca escolhida" do
    nova = configuracao

    expect(nova.save).to be(true)
    expect(nova.ponto_acesso).to have_attributes(funcionario:, catraca:, encerrado_em: nil)
    expect(funcionario.reload.ponto_acesso_atual).to eq(nova.ponto_acesso)
  end

  it "não diferencia maiúsculas de minúsculas no nome e ignora espaços sobrando" do
    expect(configuracao(restaurante: "  ru  darcy   RIBEIRO ", numero_da_catraca: " 01 ")).to be_valid
  end

  {
    { restaurante: "" } => [ :restaurante, "Informe o restaurante" ],
    { restaurante: "RU Inexistente" } => [ :restaurante, "Restaurante não encontrado" ],
    { numero_da_catraca: "" } => [ :numero_da_catraca, "Informe o número da catraca" ],
    { numero_da_catraca: "123" } => [ :numero_da_catraca, "O número da catraca deve ter 2 dígitos" ],
    { numero_da_catraca: "1" } => [ :numero_da_catraca, "O número da catraca deve ter 2 dígitos" ],
    { numero_da_catraca: "AB" } => [ :numero_da_catraca, "O número da catraca deve ter 2 dígitos" ],
    { numero_da_catraca: "99" } => [ :numero_da_catraca, "Catraca não encontrada neste restaurante" ]
  }.each do |dados, (campo, mensagem)|
    it "com #{dados.inspect}, não abre o ponto de acesso e acusa \"#{mensagem}\"" do
      invalida = configuracao(**dados)

      expect { expect(invalida.save).to be(false) }.not_to change(PontoAcesso, :count)
      expect(invalida.errors[campo]).to eq([ mensagem ])
    end
  end

  it "só acusa o restaurante quando ele não existe, sem procurar a catraca" do
    invalida = configuracao(restaurante: "RU Inexistente")

    expect(invalida).not_to be_valid
    expect(invalida.errors[:numero_da_catraca]).to be_empty
  end

  it "não aceita a catraca de outro restaurante" do
    Restaurante.create!(nome: "RU Gama", campus: "Gama")
    invalida = configuracao(restaurante: "RU Gama")

    expect(invalida).not_to be_valid
    expect(invalida.errors[:numero_da_catraca]).to eq([ "Catraca não encontrada neste restaurante" ])
  end

  it "mantém o ponto de acesso atual quando a nova configuração é inválida" do
    atual = PontoAcesso.abrir!(funcionario:, catraca:)

    configuracao(numero_da_catraca: "99").save

    expect(atual.reload.encerrado_em).to be_nil
  end
end
