import { Controller } from "@hotwired/stimulus"

// Copia o código "Pix copia e cola" para a área de transferência.
export default class extends Controller {
  static targets = ["origem", "rotulo"]

  async copiar() {
    try {
      await navigator.clipboard.writeText(this.origemTarget.value)
    } catch {
      this.origemTarget.select()
      document.execCommand("copy")
    }

    this.rotuloTarget.textContent = "Copiado!"
    clearTimeout(this.restaurar)
    this.restaurar = setTimeout(() => { this.rotuloTarget.textContent = "Copiar" }, 2000)
  }

  disconnect() {
    clearTimeout(this.restaurar)
  }
}
