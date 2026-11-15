ParameterType(
  name: "data",
  regexp: %r{\d{2}/\d{2}/\d{4}},
  transformer: ->(data) { Date.strptime(data, "%d/%m/%Y") }
)

ParameterType(
  name: "hora",
  regexp: /\d{2}:\d{2}/,
  transformer: ->(hora) { hora.split(":").map(&:to_i) }
)

ParameterType(
  name: "reais",
  regexp: /R\$ \d{1,3}(?:\.\d{3})*,\d{2}/,
  transformer: ->(texto) { ValorMonetario.new.cast(texto) }
)
