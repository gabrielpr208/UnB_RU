# language: pt
@issue-3
Funcionalidade: Visualizar extrato
  Como estudante
  Eu quero visualizar meu extrato de recargas e histórico de refeições
  Para ter controle sobre meus gastos e utilizações.

  Extrato: lista de todas as movimentações da conta (recargas e refeições)

  Regras de negócio:
  - O extrato exibido deve ser sempre o do estudante logado, sendo impossível consultar o extrato de outro estudante
  - O extrato deve exibir, para cada movimentação: tipo (recarga/refeição), valor, data e hora
  - Movimentações devem aparecer da mais recente para a mais antiga
  - Recargas só aparecem depois de confirmadas (PIX pendente ou expirado não entra no extrato)
  - O extrato pode ser filtrado por tipo (só recargas ou só refeições), por período e por faixa de valor
  - O período inclui a data inicial e a data final
  - A faixa de valor considera o valor sem o sinal (uma refeição de -4,50 está entre 4,00 e 5,00)
  - Os filtros podem ser combinados

  Contexto:
    Dado que o estudante Lucas tem uma conta com as seguintes movimentações:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |
      | recarga  | 20,00 | 10/10/2026 11:30 |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | refeição | -4,50 | 12/10/2026 11:30 |
    E a estudante Maria tem uma conta sem movimentações

  Cenário: Visualizar extrato existente próprio (feliz)
    Dado que estou logado como Lucas
    Quando consulto o meu extrato
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 12/10/2026 11:30 |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |
      | recarga  | 20,00 | 10/10/2026 11:30 |

  Cenário: Visualizar extrato vazio próprio (feliz)
    Dado que estou logado como Maria
    Quando consulto o meu extrato
    Então eu devo ver a mensagem "Sem movimentações por enquanto"

  Cenário: Visualizar extrato sem estar logado (triste)
    Dado que não estou logado
    Quando tento consultar o extrato
    Então devo ser redirecionado para a página de login
    E eu devo ver a mensagem "Você deve estar logado para ver o extrato"

  # ---------- Filtros ----------

  Cenário: Mostrar apenas as refeições (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato para mostrar apenas "Refeições"
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 12/10/2026 11:30 |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |

  Cenário: Mostrar apenas as recargas (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato para mostrar apenas "Recargas"
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | recarga  | 20,00 | 10/10/2026 11:30 |

  Cenário: Filtrar o extrato por período (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato de "11/10/2026" até "12/10/2026"
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 12/10/2026 11:30 |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | refeição | -4,50 | 11/10/2026 12:05 |

  Cenário: Filtrar o extrato por faixa de valor (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato com valores entre "4,00" e "5,00"
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 12/10/2026 11:30 |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |

  Cenário: Combinar filtros de tipo e período (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato de "10/10/2026" até "11/10/2026"
    E filtro o extrato para mostrar apenas "Refeições"
    Então eu devo ver as seguintes movimentações, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |

  Cenário: Limpar os filtros (feliz)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    E que filtrei o extrato para mostrar apenas "Recargas"
    Quando limpo os filtros
    Então eu devo ver 5 movimentações

  Cenário: Nenhuma movimentação no período filtrado (triste)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato de "01/09/2026" até "30/09/2026"
    Então eu devo ver a mensagem "Nenhuma movimentação encontrada com esses filtros"

  Cenário: Período com a data final antes da data inicial (triste)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato de "12/10/2026" até "10/10/2026"
    Então eu devo ver a mensagem "A data final não pode ser anterior à data inicial"
    E nenhuma movimentação deve ser listada

  Esquema do Cenário: Faixa de valor inválida (triste)
    Dado que estou logado como Lucas
    E que estou consultando o meu extrato
    Quando filtro o extrato com valores entre "<minimo>" e "<maximo>"
    Então eu devo ver a mensagem "<mensagem>"
    E nenhuma movimentação deve ser listada

    Exemplos:
      | minimo | maximo | mensagem                                             |
      | 20,00  | 5,00   | O valor máximo não pode ser menor que o valor mínimo |
      | abc    | 5,00   | Informe um valor numérico válido                     |
      | 1,00   | -5     | Informe um valor numérico válido                     |
