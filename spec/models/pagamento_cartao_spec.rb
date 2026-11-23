require "rails_helper"

RSpec.describe PagamentoCartao, type: :model do
  let(:estudante) { criar_estudante.tap { |e| e.update!(saldo: 10) } }

  def pagamento(**alteracoes)
    described_class.new(valor: "20,00", numero_cartao: "4111111111111111", validade: "12/2030", cvv: "123",
                        **alteracoes).tap { |p| p.estudante = estudante }
  end

  before { travel_to(Time.zone.local(2026, 11, 12, 12)) }

  describe "#save com dados válidos" do
    it "retorna true" do
      expect(pagamento.save).to be(true)
    end

    it "credita o saldo na hora" do
      pagamento.save

      expect(estudante.reload.saldo).to eq(30)
    end

    it "registra uma recarga por cartão já confirmada" do
      expect { pagamento.save }.to change(estudante.recargas.cartao.confirmada, :count).by(1)
      expect(estudante.recargas.last.confirmada_em).to eq(Time.current)
    end

    it "aceita o número do cartão com espaços" do
      expect(pagamento(numero_cartao: "4111 1111 1111 1111").save).to be(true)
    end

    it "aceita a validade com ano de 2 dígitos" do
      expect(pagamento(validade: "12/30").save).to be(true)
    end

    it "aceita um cartão que vence no mês atual" do
      travel_to(Time.zone.local(2026, 11, 30, 23, 59))

      expect(pagamento(validade: "11/2026").save).to be(true)
    end
  end

  shared_examples "pagamento recusado" do |campo, mensagem|
    it "retorna false" do
      expect(subject.save).to be(false)
    end

    it "não cria recarga nem credita o saldo" do
      expect { subject.save }.not_to change(Recarga, :count)
      expect(estudante.reload.saldo).to eq(10)
    end

    it "informa \"#{mensagem}\"" do
      subject.save

      expect(subject.errors[campo]).to include(mensagem)
    end
  end

  {
    "número com 15 dígitos" => [ { numero_cartao: "411111111111111" }, :numero_cartao, "Número do cartão inválido" ],
    "número com 17 dígitos" => [ { numero_cartao: "41111111111111111" }, :numero_cartao, "Número do cartão inválido" ],
    "número com letras" => [ { numero_cartao: "4111abcd11111111" }, :numero_cartao, "Número do cartão inválido" ],
    "cartão vencido" => [ { validade: "09/2026" }, :validade, "Cartão vencido" ],
    "cartão vencido no mês anterior" => [ { validade: "10/2026" }, :validade, "Cartão vencido" ],
    "mês inexistente" => [ { validade: "13/2030" }, :validade, "Validade inválida. Use o formato MM/AAAA" ],
    "validade fora do formato" => [ { validade: "2030-12" }, :validade, "Validade inválida. Use o formato MM/AAAA" ],
    "CVV com 2 dígitos" => [ { cvv: "12" }, :cvv, "CVV inválido" ],
    "CVV com 4 dígitos" => [ { cvv: "1234" }, :cvv, "CVV inválido" ],
    "CVV com letras" => [ { cvv: "12a" }, :cvv, "CVV inválido" ],
    "número em branco" => [ { numero_cartao: "" }, :base, "Preencha todos os dados do cartão" ],
    "validade em branco" => [ { validade: "" }, :validade, "Campo obrigatório" ],
    "CVV em branco" => [ { cvv: " " }, :base, "Preencha todos os dados do cartão" ],
    "valor abaixo do mínimo" => [ { valor: "0,00" }, :valor, "O valor mínimo de recarga é R$ 1,00" ],
    "valor acima do máximo" => [ { valor: "1500,01" }, :valor, "O valor máximo de recarga é R$ 1.000,00" ],
    "valor em branco" => [ { valor: "" }, :valor, "Informe o valor da recarga" ]
  }.each do |caso, (alteracoes, campo, mensagem)|
    context "com #{caso}" do
      subject { pagamento(**alteracoes) }

      include_examples "pagamento recusado", campo, mensagem
    end
  end

  it "reúne os erros do valor e do cartão de uma só vez" do
    invalido = pagamento(valor: "abc", numero_cartao: "123", cvv: "")

    expect(invalido).not_to be_valid
    expect(invalido.errors.attribute_names).to contain_exactly(:valor, :numero_cartao, :cvv, :base)
  end
end
