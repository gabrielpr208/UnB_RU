# language: pt
@issue-6
Funcionalidade: Validação de entrada
  Como estudante
  Eu quero passar pela catraca apresentando minha identificação
  Para que minha entrada seja liberada e a refeição debitada do meu saldo

  Regras de negócio:
  - A identificação deve ser a matrícula de um estudante cadastrado
  - O estudante deve ter saldo maior ou igual ao valor da refeição para ter a entrada liberada
  - O débito do valor da refeição só acontece quando a catraca é liberada
  - Apenas as entradas liberadas devem ser registradas no histórico da catraca

  Contexto:
    Dado que o estudante Lucas, com a matrícula "123456789", existe no sistema
    E que o preço de uma refeição é R$ 4,50
    E que a catraca 01 do RU Darcy Ribeiro está configurada


  Cenário: Entrada válida (feliz)
    Dado que Lucas tem R$ 4,50 de saldo
    Quando eu apresento a identificação "123456789" na catraca 01 do RU Darcy Ribeiro
    Então eu devo ver a mensagem "Entrada liberada"
    E a catraca deve ser liberada
    E o saldo de Lucas deve ser R$ 0,00
    E o acesso deve ser registrado no histórico da catraca

  Cenário: Saldo insuficiente (triste)
    Dado que Lucas tem R$ 4,49 de saldo
    Quando eu apresento a identificação "123456789" na catraca 01 do RU Darcy Ribeiro
    Então eu devo ver a mensagem "Saldo insuficiente"
    E a catraca deve permanecer bloqueada
    E o saldo de Lucas deve permanecer R$ 4,49
    E nenhum acesso deve ser registrado no histórico da catraca

  Esquema do Cenário: Identificação inválida (triste)
    Quando eu apresento a identificação "<identificacao>" na catraca 01 do RU Darcy Ribeiro
    Então eu devo ver a mensagem "Identificação inválida"
    E a catraca deve permanecer bloqueada
    E nenhum acesso deve ser registrado no histórico da catraca

    Exemplos:
      | identificacao |
      |  1234567891   |
      |  12345678     |
      |  12345678A    |
      |               |
      |  987654321    |
