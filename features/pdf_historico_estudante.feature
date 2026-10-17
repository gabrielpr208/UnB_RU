# language: pt
@issue-11
Funcionalidade: Exportar PDF do histórico do estudante
  Como estudante
  Eu quero poder exportar meu Extrato e Histórico de Refeições como PDF 
  Para poder controlar melhor as minhas finanças

  Regras de negócio:
  - O PDF exportado deve ser sempre o do estudante logado
  - O PDF deve exibir as movimentações no mesmo formato do extrato
  - Se o estudante não tiver movimentações, o sistema informa que não há movimentações e o PDF não é gerado

  Contexto:
    Dado que o estudante Lucas tem uma conta com as seguintes movimentações:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |
      | recarga  | 20,00 | 10/10/2026 11:30 |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | refeição | -4,50 | 12/10/2026 11:30 |
    E a estudante Maria tem uma conta sem movimentações

  Cenário: Exportar extrato existente próprio (feliz)
    Dado que estou logado como Lucas
    Quando exporto meu extrato
    Então eu devo ver as seguintes movimentações no documento, nesta ordem:
      |   tipo   | valor |     data_hora    |
      | refeição | -4,50 | 12/10/2026 11:30 |
      | recarga  | 20,00 | 12/10/2026 10:00 |
      | refeição | -4,50 | 11/10/2026 12:05 |
      | refeição | -4,50 | 10/10/2026 12:00 |
      | recarga  | 20,00 | 10/10/2026 11:30 |

  Cenário: Exportar extrato vazio próprio (feliz)
    Dado que estou logado como Maria
    Quando exporto meu extrato
    Então eu devo ver a mensagem "Sem movimentações por enquanto"
    E nenhum documento deve ser gerado

  Cenário: Exportar extrato sem estar logado (triste)
    Dado que não estou logado
    Quando tento exportar meu extrato
    Então devo ser redirecionado para a página de login
    E eu devo ver a mensagem "Você deve estar logado para ter acesso ao extrato"
