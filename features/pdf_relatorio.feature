# language: pt
@issue-12
Funcionalidade: Exportar PDF do relatório de operação
  Como administrador geral do sistema
  Eu quero poder exportar o Relatório Global de Operação
  Para fins de auditoria interna

  Relatório Global de Operação: PDF com todos os acessos de todos os restaurantes e o total de acessos de cada um

  Regras de negócio:
  - O relatório só pode ser gerado por conta logada como administrador geral
  - O relatório deve exibir, para cada acesso: estudante, restaurante, catraca, data e hora
  - Acessos devem aparecer do mais recente para o mais antigo
  - O relatório deve exibir o total de acessos de cada restaurante, inclusive os sem acessos, e o total geral

  Contexto:
    Dado que o restaurante "RU Darcy Ribeiro" possui as catracas "01" e "02"
    E que o restaurante "RU Gama" possui a catraca "01"
    E que o restaurante "RU FCE" possui a catraca "01"

  Cenário: Exportar relatório com acessos registrados (feliz)
    Dado que foram registrados os seguintes acessos:
      | estudante | restaurante      | catraca | data_hora        |
      | 231012345 | RU Gama          | 01      | 15/10/2026 12:05 |
      | 221054321 | RU Darcy Ribeiro | 01      | 16/10/2026 12:10 |
      | 191011111 | RU Gama          | 01      | 14/10/2026 11:50 |
      | 231012345 | RU Darcy Ribeiro | 01      | 16/10/2026 12:30 |
      | 201098765 | RU Darcy Ribeiro | 02      | 15/10/2026 18:45 |
    E que estou logado como administrador geral
    Quando exporto o relatório global de operação
    Então eu devo ver os seguintes acessos no documento, nesta ordem:
      | estudante | restaurante      | catraca | data_hora        |
      | 231012345 | RU Darcy Ribeiro | 01      | 16/10/2026 12:30 |
      | 221054321 | RU Darcy Ribeiro | 01      | 16/10/2026 12:10 |
      | 201098765 | RU Darcy Ribeiro | 02      | 15/10/2026 18:45 |
      | 231012345 | RU Gama          | 01      | 15/10/2026 12:05 |
      | 191011111 | RU Gama          | 01      | 14/10/2026 11:50 |
    E eu devo ver os seguintes totais no documento:
      | restaurante      | total |
      | RU Darcy Ribeiro | 3     |
      | RU Gama          | 2     |
      | RU FCE           | 0     |
      | Total geral      | 5     |

  Cenário: Exportar relatório como funcionário (triste)
    Dado que estou logado como funcionário
    Quando tento exportar o relatório global de operação
    Então eu devo ver a mensagem "Acesso restrito a administrador geral"
    E nenhum documento deve ser gerado
