# language: pt
@issue-4
Funcionalidade: Autenticação do funcionário
  Como funcionário do restaurante
  Eu quero fazer login na aplicação de controle
  Para autenticar minha sessão e operar o sistema de forma segura

  Regras de negócio:
  - Apenas funcionários podem acessar a aplicação de controle
  - O login deve ser feito com SIAPE e senha
  - SIAPE ou senha incorretos: login recusado, com mensagem genérica que não indica qual campo está errado

  Contexto:
    Dado que existe o funcionário com SIAPE "1234567" e senha "senha123"

  Cenário: Login de funcionário (feliz)
    Quando eu faço login com os seguintes dados:
      | SIAPE | 1234567  |
      | senha | senha123 |
    Então eu devo ser redirecionado para a página de aplicação de controle
    E devo ver a mensagem "Login realizado com sucesso"

  Esquema do Cenário: Login com dados inválidos (triste)
    Quando eu tento fazer login com "<siape>" e "<senha>"
    Então eu devo ver a mensagem "Erro na autenticação. Verifique os dados"
    E não devo ter acesso à aplicação de controle

    Exemplos:
      | siape    |  senha   |
      | 123456   | senha123 |
      | 12345678 | senha123 |
      | 123A567  | senha123 |
      |          | senha123 |
      | 1234567  | senha321 |
      | 1234567  |          |
      | 7654321  | senha123 |

  Cenário: Acesso por estudante (triste)
    Dado que estou logado como estudante
    Quando eu tento acessar a aplicação de controle
    Então eu devo ser redirecionado para a página de login de funcionário
    E devo ver a mensagem "Acesso por estudantes não autorizado"

