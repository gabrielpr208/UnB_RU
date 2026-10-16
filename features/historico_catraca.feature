# language: pt
@issue-7
Funcionalidade: Histórico da catraca
  Como funcionário
  Eu quero visualizar na aplicação de controle o histórico de todos os acessos registrados apenas na catraca que estou gerenciando no momento
  Para realizar auditorias ou conferências locais de fluxo

  Regras de negócio:
  - O histórico deve ser exibido apenas para a catraca configurada no ponto de acesso atual
  - O histórico deve exibir, para cada acesso: identificação do estudante, data e hora
  - Acessos devem aparecer do mais recente para o mais antigo

  Contexto:
    Dado que a catraca 01 do RU Darcy Ribeiro tem os seguintes acessos:
      | identificação |     data_hora    |
      |   123456789   | 11/10/2026 12:05 |
      |   987654321   | 11/10/2026 11:50 |
      |   987654321   | 12/10/2026 12:00 |
      |   123456789   | 11/10/2026 19:00 |
      |   123456789   | 12/10/2026 13:00 |
    E que a catraca 02 do RU Darcy Ribeiro tem os seguintes acessos:
      | identificação |     data_hora    |
      |   987654321   | 13/10/2026 11:50 |
      |   123456789   | 13/10/2026 12:05 |
    E que eu estou logado como funcionário

  Cenário: Visualizar histórico da catraca (feliz)
    Dado que a catraca 01 do RU Darcy Ribeiro está configurada como ponto de acesso
    Quando consulto o histórico
    Então eu devo ver os seguintes acessos, nesta ordem:
      | identificação |     data_hora    |
      |   123456789   | 12/10/2026 13:00 |
      |   987654321   | 12/10/2026 12:00 |
      |   123456789   | 11/10/2026 19:00 |
      |   123456789   | 11/10/2026 12:05 |
      |   987654321   | 11/10/2026 11:50 |

  Cenário: Visualizar histórico sem catraca configurada (triste)
    Dado que nenhuma catraca está configurada como ponto de acesso
    Quando tento consultar o histórico
    Então eu devo ser redirecionado para a página de configuração de ponto de acesso
    E eu devo ver a mensagem "Você deve ter uma catraca configurada para ver o histórico"
