# language: pt
@issue-5
Funcionalidade: Configuração de ponto de acesso
  Como funcionário do restaurante, logo após o login
  Eu quero selecionar em qual restaurante vou gerenciar
  Para que o sistema direcione as regras corretamente e grave os logs corretamente.

  Ponto de acesso: catraca de um restaurante em que o funcionário está operando

  Regras de negócio:
  - O ponto de acesso será identificado pela unidade operacional (campus) e pelo número da catraca (2 dígitos)
  - A unidade operacional e a catraca devem existir


  Contexto:
    Dado que eu acabei de fazer login bem-sucedido como funcionário
    E a unidade operacional "RU Darcy Ribeiro" existe
    E a catraca 01 é a única dessa unidade operacional

  Cenário: Configuração correta do ponto de acesso (feliz)
    Quando eu configuro o ponto de acesso com os seguintes dados:
      | Unidade operacional | RU Darcy Ribeiro |
      |  número da catraca  | 01               |
    Então devo ser redirecionado para a página da aplicação de controle
    E devo ver a mensagem "Configuração do ponto de acesso bem-sucedida"

  Esquema do Cenário: Configuração incorreta do ponto de acesso (triste)
    Quando eu configuro o ponto de acesso com "<unidade_operacional>" e "<catraca>"
    Então eu devo ver a mensagem "Ponto de acesso inválido"
    E devo permanecer na seleção de ponto de acesso

    Exemplos:
      | unidade_operacional | catraca |
      |  RU Darcy Ribeiro   |   123   |
      |  RU Darcy Ribeiro   |    99   |
      |  RU Inexistente     |    01   |
      |                     |    01   |
      |  RU Darcy Ribeiro   |         |
