import { Controller } from "@hotwired/stimulus"

// Envia o formulário assim que uma opção muda, como no filtro de tipo do extrato.
// Sem JavaScript, o estudante escolhe a opção e clica em "Filtrar".
export default class extends Controller {
  enviar() {
    this.element.requestSubmit()
  }
}
