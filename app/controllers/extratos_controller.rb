class ExtratosController < ApplicationController
  before_action :carregar_extrato

  def show
    render :show, status: :unprocessable_content if @extrato.invalid?
  end

  # Exporta em PDF as mesmas movimentações da tela, com os filtros aplicados (features/pdf_historico_estudante.feature).
  # Sem movimentações, volta para o extrato avisando, e nenhum documento é gerado.
  def pdf
    if @extrato.invalid?
      redirect_to extrato_path(filtros), alert: "Corrija os filtros do extrato antes de exportar"
    elsif @extrato.movimentacoes.empty?
      redirect_to extrato_path(filtros), alert: "Não há movimentações para exportar"
    else
      send_data ExtratoPdf.new(@extrato).render,
                filename: "extrato-#{@estudante.matricula}-#{Date.current.strftime('%Y-%m-%d')}.pdf",
                type: "application/pdf", disposition: "attachment"
    end
  end

  private

  def carregar_extrato
    @estudante = Current.usuario.estudante
    @extrato = Extrato.new(filtros)
    @extrato.estudante = @estudante
  end

  def filtros
    params.permit(:tipo, :data_inicial, :data_final, :valor_minimo, :valor_maximo)
  end

  def mensagem_para_pedir_login
    if action_name == "pdf"
      "Você deve estar logado para ter acesso ao extrato"
    else
      "Você deve estar logado para ver o extrato"
    end
  end
end
