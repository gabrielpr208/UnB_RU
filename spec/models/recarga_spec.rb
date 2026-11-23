require "rails_helper"

RSpec.describe Recarga, type: :model do
  let(:estudante) { criar_estudante.tap { |e| e.update!(saldo: 10) } }

  def nova_recarga(**atributos)
    described_class.new(estudante:, metodo: :pix, valor: "20,00", **atributos)
  end

  it "é válida com estudante, método e valor" do
    expect(nova_recarga).to be_valid
  end

  describe "valor" do
    {
      "1,00" => nil,
      "1000,00" => nil,
      "1.000,00" => nil,
      "0,99" => "O valor mínimo de recarga é R$ 1,00",
      "0" => "O valor mínimo de recarga é R$ 1,00",
      "1000,01" => "O valor máximo de recarga é R$ 1.000,00",
      "abc" => "Informe um valor numérico válido",
      "-5" => "Informe um valor numérico válido",
      "" => "Informe o valor da recarga",
      nil => "Informe o valor da recarga"
    }.each do |valor, mensagem|
      if mensagem
        it "#{valor.inspect} é recusado com a mensagem \"#{mensagem}\"" do
          recarga = nova_recarga(valor:)

          expect(recarga).not_to be_valid
          expect(recarga.errors[:valor]).to eq([ mensagem ])
        end
      else
        it "#{valor.inspect} é aceito" do
          expect(nova_recarga(valor:)).to be_valid
        end
      end
    end

    it "também é limitado no banco de dados" do
      recarga = nova_recarga.tap(&:save!)

      expect { recarga.update_column(:valor, 1001) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it "recusa um método de pagamento desconhecido" do
    recarga = nova_recarga(metodo: "boleto")

    expect(recarga).not_to be_valid
    expect(recarga.errors[:metodo]).to eq([ "Forma de pagamento inválida" ])
  end

  describe "PIX" do
    it "nasce pendente, com código e prazo de 1 minuto" do
      freeze_time do
        recarga = nova_recarga.tap(&:save!)

        expect(recarga).to be_pendente
        expect(recarga.codigo_pix).to start_with("000201")
        expect(recarga.codigo_pix).to include("540520.00")
        expect(recarga.expira_em).to eq(1.minute.from_now)
      end
    end

    it "gera um código diferente para cada recarga" do
      expect(nova_recarga.tap(&:save!).codigo_pix).not_to eq(nova_recarga.tap(&:save!).codigo_pix)
    end

    it "conta os segundos que faltam para expirar" do
      travel_to(Time.zone.local(2026, 11, 12, 12))
      recarga = nova_recarga.tap(&:save!)

      travel 45.seconds
      expect(recarga.segundos_restantes).to eq(15)
      expect(recarga).not_to be_prazo_esgotado

      travel 1.minute
      expect(recarga.segundos_restantes).to eq(0)
      expect(recarga).to be_prazo_esgotado
    end
  end

  describe "cartão" do
    it "não tem código PIX nem prazo" do
      recarga = nova_recarga(metodo: :cartao, status: :confirmada).tap(&:save!)

      expect(recarga.codigo_pix).to be_nil
      expect(recarga.expira_em).to be_nil
      expect(recarga).not_to be_prazo_esgotado
    end
  end

  describe "#conferir_pagamento!" do
    let!(:recarga) { nova_recarga.tap(&:save!) }

    context "dentro do prazo" do
      it "confirma o pagamento e credita o saldo" do
        travel 59.seconds do
          recarga.conferir_pagamento!

          expect(recarga).to be_confirmada
          expect(recarga.confirmada_em).to be_within(1.second).of(Time.current)
          expect(estudante.reload.saldo).to eq(30)
        end
      end

      it "credita o saldo uma única vez, mesmo conferindo de novo" do
        recarga.conferir_pagamento!
        recarga.conferir_pagamento!
        described_class.find(recarga.id).conferir_pagamento!

        expect(estudante.reload.saldo).to eq(30)
      end
    end

    context "depois do prazo" do
      it "marca a recarga como expirada e não credita o saldo" do
        travel 1.minute + 1.second do
          recarga.conferir_pagamento!
        end

        expect(recarga.reload).to be_expirada
        expect(recarga.confirmada_em).to be_nil
        expect(estudante.reload.saldo).to eq(10)
      end

      it "considera expirado exatamente no fim do prazo" do
        travel_to(recarga.expira_em, with_usec: true) { recarga.conferir_pagamento! }

        expect(recarga.reload).to be_expirada
      end
    end

    it "não faz nada com uma recarga já expirada" do
      recarga.expirada!
      recarga.conferir_pagamento!

      expect(recarga.reload).to be_expirada
      expect(estudante.reload.saldo).to eq(10)
    end
  end
end
