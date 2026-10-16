# language: pt
@issue-9
Funcionalidade: Histórico de acessos
  Como administrador
  Eu quero visualizar o histórico completo de todos os acessos do campus, podendo filtrar e agrupar por restaurante e por catraca
  Para ter uma visão gerencial de toda a operação

  Regras de negócio:
  - O histórico é exibido do acesso mais recente para o mais antigo
  - O filtro por catraca exige que um restaurante esteja selecionado e lista apenas as catracas dele
  - O agrupamento exibe o total de acessos de cada restaurante ou catraca
  - Filtros sem resultados exibem uma mensagem informativa

  Contexto:
    Dado que eu estou logado como administrador
    E que existe o restaurante "RU FCE" sem acessos registrados
    E que foram registrados os seguintes acessos:
      | estudante   | restaurante      | catraca | data_hora        |
      | 231012345   | RU Darcy Ribeiro | CAT-01  | 16/10/2026 12:30 |
      | 221054321   | RU Darcy Ribeiro | CAT-01  | 16/10/2026 12:10 |
      | 201098765   | RU Darcy Ribeiro | CAT-02  | 15/10/2026 18:45 |
      | 231012345   | RU Gama          | CAT-01  | 15/10/2026 12:05 |
      | 191011111   | RU Gama          | CAT-01  | 14/10/2026 11:50 |

  # ---------- Visualizar ----------

  Cenário: Visualizar o histórico completo (feliz)
    Quando eu acesso o histórico de acessos
    Então eu devo ver 5 acessos
    E cada acesso deve exibir estudante, restaurante, catraca e data/hora
    E o primeiro acesso da lista deve ser o de "16/10/2026 12:30"
    E o último acesso da lista deve ser o de "14/10/2026 11:50"

  # ---------- Filtrar ----------

  Esquema do Cenário: Filtrar por restaurante (feliz)
    Quando eu filtro o histórico pelo restaurante "<restaurante>"
    Então eu devo ver <quantidade> acessos
    E todos os acessos exibidos devem ser do restaurante "<restaurante>"

    Exemplos:
      | restaurante      | quantidade |
      | RU Darcy Ribeiro | 3          |
      | RU Gama          | 2          |

  Esquema do Cenário: Filtrar por restaurante e catraca (feliz)
    Quando eu filtro o histórico pelo restaurante "<restaurante>" e pela catraca "<catraca>"
    Então eu devo ver <quantidade> acessos
    E todos os acessos exibidos devem ser da catraca "<catraca>" do "<restaurante>"

    Exemplos:
      | restaurante      | catraca | quantidade |
      | RU Darcy Ribeiro | CAT-01  | 2          |
      | RU Darcy Ribeiro | CAT-02  | 1          |
      | RU Gama          | CAT-01  | 2          |

  Cenário: Opções de catraca dependem do restaurante selecionado (feliz)
    Quando eu acesso o histórico de acessos
    E eu seleciono o restaurante "RU Gama" no filtro
    Então as opções de catraca devem ser apenas "CAT-01"

  Cenário: Filtrar por catraca sem selecionar restaurante (triste)
    Quando eu acesso o histórico de acessos
    Então o filtro de catraca deve estar desabilitado
    E eu devo ver a dica "Selecione um restaurante para filtrar por catraca"

  Cenário: Filtro sem resultados (triste)
    Quando eu filtro o histórico pelo restaurante "RU FCE"
    Então eu devo ver a mensagem "Nenhum acesso encontrado para os filtros selecionados"
    E eu não devo ver nenhum acesso na lista

  # ---------- Agrupar ----------

  Cenário: Agrupar por restaurante (feliz)
    Quando eu agrupo o histórico por restaurante
    Então eu devo ver os seguintes totais:
      | grupo            | total |
      | RU Darcy Ribeiro | 3     |
      | RU Gama          | 2     |

  Cenário: Agrupar por catraca (feliz)
    Quando eu agrupo o histórico por catraca
    Então eu devo ver os seguintes totais:
      | grupo                     | total |
      | RU Darcy Ribeiro - CAT-01 | 2     |
      | RU Darcy Ribeiro - CAT-02 | 1     |
      | RU Gama - CAT-01          | 2     |

  Cenário: Filtrar por restaurante e agrupar por catraca (feliz)
    Quando eu filtro o histórico pelo restaurante "RU Darcy Ribeiro"
    E eu agrupo o histórico por catraca
    Então eu devo ver os seguintes totais:
      | grupo                     | total |
      | RU Darcy Ribeiro - CAT-01 | 2     |
      | RU Darcy Ribeiro - CAT-02 | 1     |