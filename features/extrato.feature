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
