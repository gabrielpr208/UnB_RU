# Extrato do estudante no Portal do Estudante, com filtros e exportação em PDF (features/extrato.feature e
# features/pdf_historico_estudante.feature).
class ExtratosController < ApplicationController
  before_action :carregar_extrato

  # Mostra o extrato com os filtros escolhidos.
  #
  # Argumentos:: nenhum; os filtros vêm de +params+ (ver #filtros).
  # Retorno:: nenhum.
  # Efeitos colaterais:: renderiza a view +show+, com status 422 se algum filtro é inválido.
  def show
    render :show, status: :unprocessable_content if @extrato.invalid?
  end

  # Exporta em PDF as mesmas movimentações da tela, com os filtros aplicados. Sem movimentações, volta para o
  # extrato avisando, e nenhum documento é gerado.
  #
  # Argumentos:: nenhum; os filtros vêm de +params+ (ver #filtros).
  # Retorno:: nenhum.
  # Efeitos colaterais::
  #   envia o arquivo <tt>extrato-MATRICULA-AAAA-MM-DD.pdf</tt> como download (ver ExtratoPdf); com filtros
  #   inválidos ou sem movimentações, redireciona para o extrato com um alerta.
  def pdf
    if @extrato.invalid?
      voltar_ao_extrato "Corrija os filtros do extrato antes de exportar"
    elsif @extrato.movimentacoes.empty?
      voltar_ao_extrato "Não há movimentações para exportar"
    else
      send_data ExtratoPdf.new(@extrato).render, filename: nome_do_pdf, type: "application/pdf", disposition: "attachment"
    end
  end

  private

  # Volta para a tela do extrato, mantendo os filtros.
  #
  # Argumentos::
  #   - +alerta+: mensagem mostrada ao estudante.
  # Retorno:: nenhum.
  # Efeitos colaterais:: redireciona para o extrato com os mesmos filtros e o alerta.
  def voltar_ao_extrato(alerta)
    redirect_to extrato_path(filtros), alert: alerta
  end

  # Nome do arquivo PDF do extrato.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ como <tt>"extrato-231012345-2026-03-01.pdf"</tt> (matrícula e data de hoje).
  # Efeitos colaterais:: nenhum.
  def nome_do_pdf
    "extrato-#{@estudante.matricula}-#{Date.current.strftime('%Y-%m-%d')}.pdf"
  end

  # Filtro que monta o extrato do estudante logado com os filtros da URL.
  #
  # Argumentos:: nenhum.
  # Retorno:: o Estudante logado.
  # Efeitos colaterais:: define <tt>@estudante</tt> e <tt>@extrato</tt>.
  def carregar_extrato
    @estudante = Current.usuario.estudante
    @extrato = Extrato.new(filtros)
    @extrato.estudante = @estudante
  end

  # Filtros permitidos do extrato.
  #
  # Argumentos:: nenhum.
  # Retorno::
  #   <tt>ActionController::Parameters</tt> com +tipo+, +data_inicial+, +data_final+, +valor_minimo+ e
  #   +valor_maximo+ (os que vieram na URL).
  # Efeitos colaterais:: nenhum.
  def filtros
    params.permit(:tipo, :data_inicial, :data_final, :valor_minimo, :valor_maximo)
  end

  # Mensagem mostrada a quem tenta abrir o extrato sem estar logado.
  #
  # Argumentos:: nenhum.
  # Retorno:: +String+ com a mensagem, diferente para a tela e para o PDF.
  # Efeitos colaterais:: nenhum.
  def mensagem_para_pedir_login
    if action_name == "pdf"
      "Você deve estar logado para ter acesso ao extrato"
    else
      "Você deve estar logado para ver o extrato"
    end
  end
end
