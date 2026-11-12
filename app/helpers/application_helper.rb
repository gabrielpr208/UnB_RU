module ApplicationHelper
  ICONES = {
    usuario: '<circle cx="12" cy="8" r="4"/><path d="M4 21v-1a6 6 0 0 1 6-6h4a6 6 0 0 1 6 6v1"/>',
    matricula: '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2"/>' \
               '<path d="M6 16a3.2 3.2 0 0 1 6 0"/><path d="M15 10h3"/><path d="M15 14h3"/>',
    email: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/>',
    cadeado: '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>',
    confirmar: '<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>',
    alerta: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5"/><path d="M12 16.5h.01"/>',
    seta: '<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>',
    entrar: '<path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"/><path d="m10 17 5-5-5-5"/><path d="M15 12H3"/>',
    cartao: '<rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/><path d="M6 15h4"/>',
    qrcode: '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/>' \
            '<rect x="3" y="14" width="7" height="7" rx="1"/><path d="M14 14h3v3"/><path d="M21 14v.01"/>' \
            '<path d="M14 21h.01"/><path d="M17 21h4v-4"/>',
    escudo: '<path d="M12 3 4 6v6c0 4.5 3.4 8.2 8 9 4.6-.8 8-4.5 8-9V6z"/><path d="m9 12 2 2 4-4"/>'
  }.freeze

  def icone(nome, classe: nil)
    tag.svg(
      ICONES.fetch(nome).html_safe,
      class: [ "icone", classe ],
      viewBox: "0 0 24 24", fill: "none", stroke: "currentColor",
      "stroke-width": 2, "stroke-linecap": "round", "stroke-linejoin": "round",
      aria: { hidden: true }, focusable: false
    )
  end

  def link_de_aba(texto, caminho)
    ativa = request.path == caminho
    link_to texto, caminho, class: [ "abas__item", ("abas__item--ativa" if ativa) ],
                            aria: { current: ("page" if ativa) }
  end
end
