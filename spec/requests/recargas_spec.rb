require "rails_helper"

RSpec.describe "Recarga de saldo", type: :request do
  let!(:estudante) { criar_estudante(matricula: "231012345").tap { |e| e.update!(saldo: 10) } }

  def gerar_pix(valor = "20,00")
    post gerar_pix_path, params: { recarga: { valor: } }
  end

  def pagar_com_cartao(**alteracoes)
    dados = { valor: "20,00", numero_cartao: "4111111111111111", validade: "12/2030", cvv: "123" }
    post pagar_cartao_path, params: { pagamento_cartao: dados.merge(alteracoes) }
  end

  context "sem login" do
    it "manda para o login e depois volta para a recarga" do
      get nova_recarga_path
      expect(response).to redirect_to(login_path)

      entrar_como(estudante)
      expect(response).to redirect_to(nova_recarga_url)
    end

    it "não deixa gerar PIX nem pagar com cartão" do
      expect { gerar_pix }.not_to change(Recarga, :count)
      expect(response).to redirect_to(login_path)

      pagar_com_cartao
      expect(response).to redirect_to(login_path)
      expect(estudante.reload.saldo).to eq(10)
    end
  end

  context "com login" do
    before { entrar_como(estudante) }

    describe "GET /recarga" do
      it "abre no PIX e mostra o saldo atual" do
        get nova_recarga_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Gerar código PIX")
        expect(response.body).to include("R$ 10,00")
        expect(response.body).to include(%(class="segmentos__item segmentos__item--ativo" aria-current="page" href="#{nova_recarga_path(forma: "pix")}"))
      end

      it "mostra os campos do cartão na aba de cartão de crédito" do
        get nova_recarga_path(forma: "cartao")

        expect(response.body).to include("Efetuar pagamento")
        %w[ valor numero_cartao validade cvv ].each do |campo|
          expect(response.body).to include(%(id="pagamento_cartao_#{campo}"))
        end
      end

      it "não deixa o navegador preencher cartões reais salvos" do
        get nova_recarga_path(forma: "cartao")

        expect(response.body).to include(%(autocomplete="off" type="text" name="pagamento_cartao[numero_cartao]"))
      end

      it "volta para o PIX com uma forma de pagamento desconhecida" do
        get nova_recarga_path(forma: "boleto")

        expect(response.body).to include("Gerar código PIX")
      end

      it "destaca a aba \"Adicionar créditos\"" do
        get nova_recarga_path

        expect(response.body).to include(%(class="abas__item abas__item--ativa" aria-current="page" href="#{nova_recarga_path}"))
      end
    end

    describe "POST /recarga/pix" do
      it "cria uma recarga PIX pendente e mostra o QR Code" do
        expect { gerar_pix }.to change(estudante.recargas.pix.pendente, :count).by(1)

        expect(response).to redirect_to(recarga_pix_path(estudante.recargas.last))
      end

      it "não credita o saldo antes da conferência" do
        gerar_pix

        expect(estudante.reload.saldo).to eq(10)
      end

      {
        "0,99" => "O valor mínimo de recarga é R$ 1,00",
        "1000,01" => "O valor máximo de recarga é R$ 1.000,00",
        "abc" => "Informe um valor numérico válido",
        "" => "Informe o valor da recarga"
      }.each do |valor, mensagem|
        it "recusa #{valor.inspect} com a mensagem \"#{mensagem}\"" do
          expect { gerar_pix(valor) }.not_to change(Recarga, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(mensagem)
          expect(response.body).to include("Gerar código PIX")
        end
      end

      it "responde 400 sem os dados do formulário" do
        post gerar_pix_path, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end

    describe "GET /recarga/pix/:id" do
      let(:recarga) { estudante.recargas.create!(metodo: :pix, valor: 20) }

      it "mostra o QR Code, o código copia e cola e o botão de conferir" do
        get recarga_pix_path(recarga)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="qrcode"')
        expect(response.body).to include(%(value="#{recarga.codigo_pix}"))
        expect(response.body).to include("Conferir pagamento")
        expect(response.body).to include("R$ 20,00")
      end

      it "mostra quanto tempo falta para o código expirar" do
        travel_to(recarga.expira_em - 45.seconds, with_usec: true)
        get recarga_pix_path(recarga)

        expect(response.body).to include('data-contagem-regressiva-segundos-value="45"')
        expect(response.body).to include("0:45")
      end

      it "manda gerar um novo código quando o prazo acabou" do
        travel_to(recarga.expira_em + 1.second)
        get recarga_pix_path(recarga)

        expect(response).to redirect_to(nova_recarga_path)
        expect(flash[:alert]).to eq("Código PIX expirado. Gere um novo código")
      end

      it "avisa quando o pagamento já foi confirmado" do
        recarga.conferir_pagamento!
        get recarga_pix_path(recarga)

        expect(response).to redirect_to(nova_recarga_path)
        expect(flash[:notice]).to eq("Este pagamento já foi confirmado")
      end

      it "não mostra o PIX de outro estudante" do
        outro = criar_estudante(matricula: "200000000", email: "outro@aluno.unb.br")
        recarga_alheia = outro.recargas.create!(metodo: :pix, valor: 20)

        get recarga_pix_path(recarga_alheia)

        expect(response).to have_http_status(:not_found)
      end

      it "não abre recargas de cartão como se fossem PIX" do
        recarga_cartao = estudante.recargas.create!(metodo: :cartao, status: :confirmada, valor: 20)

        get recarga_pix_path(recarga_cartao)

        expect(response).to have_http_status(:not_found)
      end
    end

    describe "POST /recarga/pix/:id/conferir" do
      let!(:recarga) { estudante.recargas.create!(metodo: :pix, valor: 20) }

      it "dentro do prazo, credita o saldo e confirma o pagamento" do
        travel_to(recarga.expira_em - 1.second)
        post conferir_pix_path(recarga)

        expect(estudante.reload.saldo).to eq(30)
        expect(recarga.reload).to be_confirmada
        expect(response).to redirect_to(nova_recarga_path)
        expect(flash[:notice]).to eq("Pagamento confirmado! R$ 20,00 adicionados ao seu saldo")
      end

      it "depois do prazo, recusa o pagamento e não credita o saldo" do
        travel_to(recarga.expira_em + 1.second)
        post conferir_pix_path(recarga)

        expect(estudante.reload.saldo).to eq(10)
        expect(recarga.reload).to be_expirada
        expect(flash[:alert]).to eq("Código PIX expirado. Gere um novo código")
      end

      it "credita uma única vez, mesmo com dois cliques" do
        2.times { post conferir_pix_path(recarga) }

        expect(estudante.reload.saldo).to eq(30)
      end

      it "não confere o PIX de outro estudante" do
        outro = criar_estudante(matricula: "200000000", email: "outro@aluno.unb.br")
        recarga_alheia = outro.recargas.create!(metodo: :pix, valor: 20)

        post conferir_pix_path(recarga_alheia)

        expect(response).to have_http_status(:not_found)
        expect(outro.reload.saldo).to eq(0)
        expect(estudante.reload.saldo).to eq(10)
      end
    end

    describe "POST /recarga/cartao" do
      before { travel_to(Time.zone.local(2026, 11, 12, 12)) }

      it "com dados válidos, credita o saldo na hora" do
        pagar_com_cartao

        expect(estudante.reload.saldo).to eq(30)
        expect(estudante.recargas.cartao.confirmada.count).to eq(1)
        expect(response).to redirect_to(nova_recarga_path(forma: "cartao"))
        expect(flash[:notice]).to eq("Créditos adicionados com sucesso! R$ 20,00 no seu saldo")
      end

      {
        "número com 15 dígitos" => [ { numero_cartao: "411111111111111" }, "Número do cartão inválido" ],
        "cartão vencido" => [ { validade: "09/2026" }, "Cartão vencido" ],
        "CVV com 2 dígitos" => [ { cvv: "12" }, "CVV inválido" ],
        "número em branco" => [ { numero_cartao: "" }, "Preencha todos os dados do cartão" ],
        "valor acima do máximo" => [ { valor: "1500,01" }, "O valor máximo de recarga é R$ 1.000,00" ]
      }.each do |caso, (alteracoes, mensagem)|
        it "com #{caso}, recusa com a mensagem \"#{mensagem}\"" do
          expect { pagar_com_cartao(**alteracoes) }.not_to change(Recarga, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include(mensagem)
          expect(response.body).to include("Não foi possível concluir o pagamento")
          expect(estudante.reload.saldo).to eq(10)
        end
      end

      it "mantém o valor e o número digitados, mas pede o CVV de novo" do
        pagar_com_cartao(validade: "09/2026", cvv: "987")

        expect(response.body).to include('value="20,00"')
        expect(response.body).to include('value="4111111111111111"')
        expect(response.body).not_to include("987")
      end

      it "responde 400 sem os dados do formulário" do
        post pagar_cartao_path, params: {}

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "registro em log" do
    it "não grava o número do cartão nem o CVV" do
      filtro = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      filtrados = filtro.filter("pagamento_cartao" => { "numero_cartao" => "4111111111111111", "cvv" => "123" })

      expect(filtrados["pagamento_cartao"]).to eq("numero_cartao" => "[FILTERED]", "cvv" => "[FILTERED]")
    end
  end
end
