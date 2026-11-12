import { Controller } from "@hotwired/stimulus"

// Mostra quanto falta para o código PIX expirar. É só visual: quem decide se o código
// ainda vale é o servidor, quando o estudante clica em "Conferir pagamento".
export default class extends Controller {
  static targets = ["tempo", "aviso"]
  static values = { segundos: Number }

  connect() {
    this.fim = Date.now() + this.segundosValue * 1000
    this.atualizar()
    this.intervalo = setInterval(() => this.atualizar(), 1000)
  }

  disconnect() {
    clearInterval(this.intervalo)
  }

  atualizar() {
    const restante = Math.max(0, Math.ceil((this.fim - Date.now()) / 1000))
    const minutos = Math.floor(restante / 60)
    const segundos = String(restante % 60).padStart(2, "0")
    this.tempoTarget.textContent = `${minutos}:${segundos}`

    if (restante === 0) {
      clearInterval(this.intervalo)
      this.element.classList.add("pix--expirado")
      this.avisoTarget.hidden = false
    }
  }
}
