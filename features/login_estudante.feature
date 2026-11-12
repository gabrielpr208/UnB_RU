# language: pt
Funcionalidade: Login do estudante
  Como estudante
  Eu quero entrar na minha conta com matrícula e senha
  Para consultar meu saldo e adicionar créditos

  Regras de negócio:
  - O login deve ser feito com matrícula e senha
  - Matrícula ou senha incorretas: login recusado, com mensagem genérica que não indica qual campo está errado
  - As páginas do estudante só podem ser acessadas por quem está logado

  Contexto:
    Dado que existe o estudante "Maria Souza" com matrícula "231012345" e senha "senha123"

  Cenário: Login com dados válidos (feliz)
    Dado que eu estou na página de login
    Quando eu faço login com a matrícula "231012345" e a senha "senha123"
    Então eu devo estar na página inicial do estudante
    E eu devo ver a mensagem "Login realizado com sucesso"
    E eu devo ver a mensagem "Olá, Maria"

  Esquema do Cenário: Login com dados inválidos (triste)
    Dado que eu estou na página de login
    Quando eu faço login com a matrícula "<matricula>" e a senha "<senha>"
    Então eu devo ver a mensagem "Erro na autenticação. Verifique os dados"
    E eu não devo estar logado

    Exemplos:
      | matricula | senha    |
      | 231012345 | senha321 |
      | 231012346 | senha123 |
      | 23101234A | senha123 |
      |           | senha123 |
      | 231012345 |          |

  Cenário: Acessar a página do estudante sem estar logado (triste)
    Dado que não estou logado
    Quando eu tento acessar a página inicial do estudante
    Então eu devo ser redirecionado para a página de login
    E eu devo ver a mensagem "Você deve estar logado para acessar esta página"

  Cenário: Sair da conta (feliz)
    Dado que eu estou logado como estudante
    Quando eu saio da minha conta
    Então eu devo ser redirecionado para a página de login
    E eu devo ver a mensagem "Você saiu da sua conta"
    E eu não devo estar logado
