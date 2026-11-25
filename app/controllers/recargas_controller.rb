# Recarga de créditos no Portal do Estudante, via PIX ou cartão de crédito (ver Recarga e PagamentoCartao).
class RecargasController < ApplicationController
  # Formas de pagamento que têm aba na tela de recarga.
  FORMAS = %w[ pix cartao ].freeze

  before_action :definir_estudante
  before_action :definir_recarga_pix, only: %i[ pix conferir_pix ]

  # Mostra a tela de recarga na aba da forma de pagamento escolhida.
  #
  # Argumentos:: nenhum; a forma vem de <tt>params[:forma]</tt> (<tt>"pix"</tt>, o padrão, ou <tt>"cartao"</tt>).
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +new+.
  def new
    renderizar_formulario(params[:forma])
  end

  # Gera uma recarga PIX pendente com o valor informado.
  #
  # Argumentos:: nenhum; o valor vem de <tt>params[:recarga][:valor]</tt>.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   com valor válido, cria a Recarga pendente (com o código PIX) no banco e redireciona para a tela do
  #   código; senão, renderiza a aba PIX com os erros (status 422).
  def gerar_pix
    @recarga_pix = Recarga.new(estudante: @estudante, metodo: :pix, valor: params.expect(recarga: [ :valor ])[:valor])

    if @recarga_pix.save
      redirect_to recarga_pix_path(@recarga_pix)
    else
      renderizar_formulario("pix", status: :unprocessable_content)
    end
  end

  # Mostra o QR Code e o código "copia e cola" de uma recarga PIX pendente.
  #
  # Argumentos:: nenhum; a recarga vem de <tt>params[:id]</tt> (ver #definir_recarga_pix).
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   renderiza a view +pix+; se a recarga já foi confirmada ou o código venceu, redireciona para a tela de
  #   recarga com o aviso correspondente.
  def pix
    if @recarga.confirmada?
      redirect_to nova_recarga_path, notice: "Este pagamento já foi confirmado"
    elsif @recarga.expirada? || @recarga.prazo_esgotado?
      redirect_to nova_recarga_path, alert: "Código PIX expirado. Gere um novo código"
    end
  end

  # Confere o pagamento de uma recarga PIX (ver Recarga#conferir_pagamento!).
  #
  # Argumentos:: nenhum; a recarga vem de <tt>params[:id]</tt>.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   dentro do prazo, confirma a recarga e credita o saldo no banco; fora do prazo, marca a recarga como
  #   expirada. Nos dois casos, redireciona para a tela de recarga com o resultado.
  def conferir_pix
    @recarga.conferir_pagamento!

    if @recarga.confirmada?
      redirect_to nova_recarga_path, notice: "Pagamento confirmado! #{reais(@recarga.valor)} adicionados ao seu saldo"
    else
      redirect_to nova_recarga_path, alert: "Código PIX expirado. Gere um novo código"
    end
  end

  # Paga uma recarga com cartão de crédito (ver PagamentoCartao).
  #
  # Argumentos:: nenhum; o valor e os dados do cartão vêm de <tt>params[:pagamento_cartao]</tt>.
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   com dados válidos, cria a Recarga confirmada, credita o saldo no banco e redireciona para a aba do cartão
  #   com um aviso de sucesso; senão, renderiza a aba do cartão com os erros (status 422).
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

  # Filtro que carrega o estudante logado.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Estudante logado.
  # Efeitos colaterais:: define <tt>@estudante</tt>.
  def definir_estudante
    @estudante = Current.usuario.estudante
  end

  # Filtro que carrega a recarga PIX indicada na URL. Só encontra recargas do próprio estudante.
  #
  # Argumentos:: nenhum; usa <tt>params[:id]</tt>.
  # Retorno:: a Recarga encontrada.
  # Efeitos colaterais::
  #   define <tt>@recarga</tt>; responde 404 se a recarga não existe, não é PIX ou é de outro estudante.
  def definir_recarga_pix
    @recarga = @estudante.recargas.pix.find(params[:id])
  end

  # Renderiza a tela de recarga com as duas abas, aberta na forma de pagamento indicada.
  #
  # Argumentos::
  #   - +forma+: aba aberta (<tt>"pix"</tt> ou <tt>"cartao"</tt>; qualquer outro valor abre a do PIX).
  #   - +status+: status HTTP da resposta (padrão: +:ok+).
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   define <tt>@forma</tt> e, se ainda não existirem, formulários em branco em <tt>@recarga_pix</tt> e
  #   <tt>@pagamento_cartao</tt>; renderiza a view +new+.
  def renderizar_formulario(forma, status: :ok)
    @forma = FORMAS.include?(forma) ? forma : "pix"
    @recarga_pix ||= Recarga.new(metodo: :pix)
    @pagamento_cartao ||= PagamentoCartao.new
    render :new, status:
  end

  # Formata um valor em reais para as mensagens (ver ApplicationHelper#reais).
  #
  # Argumentos::
  #   - +valor+: número a formatar.
  # Retorno:: +String+ como <tt>"R$ 20,00"</tt>.
  # Efeitos colaterais:: nenhum.
  def reais(valor)
    helpers.reais(valor)
  end
end
