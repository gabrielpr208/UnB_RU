# language: pt
@issue-10
Funcionalidade: Visualizar cardápio da refeição atual
  Como estudante
  Eu quero ver o cardápio da refeição que está sendo servida agora, incluindo as opções padrão, ovolactovegetariana e vegetariana estrita
  Para saber o que será servido antes de ir ao restaurante

  Regras de negócio:
  - Horários: café da manhã 07:00–09:00, almoço 11:00–14:30, jantar 17:00–19:30 (início e fim inclusivos)
  - O cardápio exibido é o da refeição atual, no dia atual
  - Fora do horário de refeição, o sistema informa a próxima refeição
  - Opções não cadastradas aparecem como indisponíveis
  - Se não houver cardápio cadastrado para a refeição, o sistema informa que ele ainda não foi divulgado

  Contexto:
    Dado que eu estou logado como estudante
    E que o cardápio de 16/10/2026 é:
      | refeicao        | padrao                 | ovolactovegetariano      | vegetariano_estrito    |
      | Café da manhã   | Pão com ovos mexidos   | Pão com ovos mexidos     | Pão com pasta de grão  |
      | Almoço          | Frango grelhado        | Omelete de legumes       | Estrogonofe de grão    |
      | Jantar          | Carne de panela        | Torta de queijo          |                        |

  # ---------- Refeição sendo servida ----------

  Esquema do Cenário: Ver cardápio dentro do horário da refeição (feliz)
    Dado que agora são <horario> de 16/10/2026
    Quando eu acesso o cardápio
    Então eu devo ver o cardápio do "<refeicao>"

    Exemplos:
      | horario | refeicao      |
      | 07:00   | Café da manhã |
      | 09:00   | Café da manhã |
      | 11:00   | Almoço        |
      | 14:30   | Almoço        |
      | 17:00   | Jantar        |
      | 19:30   | Jantar        |

  Cenário: Ver as três opções da refeição atual (feliz)
    Dado que agora são 12:00 de 16/10/2026
    Quando eu acesso o cardápio
    Então eu devo ver as seguintes opções:
      | opcao                | prato               |
      | Padrão               | Frango grelhado     |
      | Ovolactovegetariano  | Omelete de legumes  |
      | Vegetariano estrito  | Estrogonofe de grão |

  # ---------- Fora do horário ----------

  Esquema do Cenário: Acessar o cardápio fora do horário de refeição (triste)
    Dado que agora são <horario> de 16/10/2026
    Quando eu acesso o cardápio
    Então eu devo ver a mensagem "Nenhuma refeição sendo servida no momento"
    E eu devo ver que a próxima refeição é "<proxima>"

    Exemplos:
      | horario | proxima                         |
      | 06:59   | Café da manhã às 07:00          |
      | 09:01   | Almoço às 11:00                 |
      | 10:59   | Almoço às 11:00                 |
      | 14:31   | Jantar às 17:00                 |
      | 16:59   | Jantar às 17:00                 |
      | 19:31   | Café da manhã de amanhã às 07:00 |

  # ---------- Cardápio incompleto ou ausente ----------

  Cenário: Refeição com opção não cadastrada (triste)
    Dado que agora são 18:00 de 16/10/2026
    Quando eu acesso o cardápio
    Então eu devo ver a opção "Padrão" com o prato "Carne de panela"
    E eu devo ver a opção "Ovolactovegetariano" com o prato "Torta de queijo"
    E eu devo ver a opção "Vegetariano estrito" como "Indisponível nesta refeição"

  Cenário: Cardápio do dia ainda não divulgado (triste)
    Dado que agora são 12:00 de 17/10/2026
    Quando eu acesso o cardápio
    Então eu devo ver a mensagem "O cardápio desta refeição ainda não foi divulgado"
