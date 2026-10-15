# language: pt
@issue-1
Funcionalidade: Cadastro de estudante
  Como estudante
  Eu quero me cadastrar no sistema utilizando minha matrícula
  Para que eu possa criar minha conta de acesso ao RU

  Regras de negócio:
  - A matrícula deve ter exatamente 9 dígitos numéricos
  - Cada matrícula só pode ser cadastrada uma vez
  - Nome, e-mail e senha são obrigatórios
  - A senha deve ter no mínimo 6 caracteres e ser igual à confirmação

  Contexto:
    Dado que eu estou na página de cadastro

  Cenário: Cadastro com dados válidos (feliz)
    Quando eu me cadastro com os seguintes dados:
      | nome               | Maria Souza             |
      | matricula          | 231012345               |
      | email              | maria@aluno.unb.br      |
      | senha              | senha123                |
      | confirmacao_senha  | senha123                |
    Então eu devo ver a mensagem "Cadastro realizado com sucesso"
    E eu devo ser redirecionado para a página de login

  Esquema do Cenário: Cadastro com matrícula inválida (triste)
    Quando eu me cadastro com a matrícula "<matricula>" e os demais dados válidos
    Então eu devo ver a mensagem "<mensagem>"
    E minha conta não deve ser criada

    Exemplos:
      | matricula  | mensagem                                   |
      | 23101234   | A matrícula deve conter 9 dígitos          |
      | 2310123456 | A matrícula deve conter 9 dígitos          |
      | 23A012345  | A matrícula deve conter apenas números     |
      |            | A matrícula é obrigatória                  |

  Cenário: Cadastro com matrícula já cadastrada (triste)
    Dado que já existe um estudante cadastrado com a matrícula "231012345"
    Quando eu me cadastro com a matrícula "231012345" e os demais dados válidos
    Então eu devo ver a mensagem "Esta matrícula já está cadastrada"
    E minha conta não deve ser criada

  Cenário: Cadastro com senha e confirmação diferentes (triste)
    Quando eu me cadastro com a senha "senha123" e a confirmação "outra456"
    Então eu devo ver a mensagem "A confirmação de senha não confere"
    E minha conta não deve ser criada