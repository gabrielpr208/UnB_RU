class RecargasController < ApplicationController
  FORMAS = %w[ pix cartao ].freeze

  before_action :definir_estudante
  before_action :definir_recarga_pix, only: %i[ pix conferir_pix ]

  def new
    renderizar_formulario(params[:forma])
  end

  def gerar_pix
    @recarga_pix = Recarga.new(estudante: @estudante, metodo: :pix, valor: params.expect(recarga: [ :valor ])[:valor])

    if @recarga_pix.save
      redirect_to recarga_pix_path(@recarga_pix)
    else
      renderizar_formulario("pix", status: :unprocessable_content)
    end
  end

  def pix
    if @recarga.confirmada?
      redirect_to nova_recarga_path, notice: "Este pagamento já foi confirmado"
    elsif @recarga.expirada? || @recarga.prazo_esgotado?
      redirect_to nova_recarga_path, alert: "Código PIX expirado. Gere um novo código"
    end
  end

  def conferir_pix
    @recarga.conferir_pagamento!

    if @recarga.confirmada?
      redirect_to nova_recarga_path, notice: "Pagamento confirmado! #{reais(@recarga.valor)} adicionados ao seu saldo"
    else
      redirect_to nova_recarga_path, alert: "Código PIX expirado. Gere um novo código"
    end
  end

  def pagar_cartao
    @pagamento_cartao = PagamentoCartao.new(params.expect(pagamento_cartao: [ :valor, :numero_cartao, :validade, :cvv ]))
    @pagamento_cartao.estudante = @estudante

    if @pagamento_cartao.save
      redirect_to nova_recarga_path(forma: "cartao"),
                  notice: "Créditos adicionados com sucesso! #{reais(@pagamento_cartao.recarga.valor)} no seu saldo"
    else
      renderizar_formulario("cartao", status: :unprocessable_content)
    end
  end

  private

  def definir_estudante
    @estudante = Current.usuario.estudante
  end

  # Só encontra recargas do próprio estudante: a de outra pessoa responde 404.
  def definir_recarga_pix
    @recarga = @estudante.recargas.pix.find(params[:id])
  end

  def renderizar_formulario(forma, status: :ok)
    @forma = FORMAS.include?(forma) ? forma : "pix"
    @recarga_pix ||= Recarga.new(metodo: :pix)
    @pagamento_cartao ||= PagamentoCartao.new
    render :new, status:
  end

  def reais(valor)
    helpers.reais(valor)
  end
end
