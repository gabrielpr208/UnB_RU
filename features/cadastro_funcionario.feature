# language: pt
@issue-4
Funcionalidade: Cadastro de funcionário
  Como administrador
  Eu quero cadastrar funcionários e escolher se cada um será administrador
  Para que eles possam entrar na Aplicação de Controle com o SIAPE

  Regras de negócio:
  - Só o administrador cadastra funcionários
  - O SIAPE deve ter exatamente 7 dígitos numéricos e ser único
  - Nome, e-mail e senha são obrigatórios, e o e-mail é único
  - A senha deve ter no mínimo 6 caracteres e ser igual à confirmação
  - Se o perfil não for escolhido, o funcionário não é administrador

  Esquema do Cenário: Cadastrar funcionário escolhendo o perfil (feliz)
    Dado que eu estou logado como administrador
    Quando eu cadastro o funcionário "Carlos Dias" com SIAPE "1112223" e perfil "<perfil>"
    Então eu devo ver a mensagem "Funcionário cadastrado com sucesso"
    E o funcionário com SIAPE "1112223" deve aparecer na lista com o perfil "<perfil>"
    E o funcionário com SIAPE "1112223" deve conseguir entrar com a senha "senha123"

    Exemplos:
      | perfil        |
      | Funcionário   |
      | Administrador |

  Cenário: Cadastrar funcionário sem escolher o perfil (feliz)
    Dado que eu estou logado como administrador
    Quando eu cadastro um funcionário com "SIAPE" igual a "1112223" e os demais dados válidos
    Então o funcionário com SIAPE "1112223" deve aparecer na lista com o perfil "Funcionário"

  Esquema do Cenário: Cadastrar funcionário com dados inválidos (triste)
    Dado que eu estou logado como administrador
    Quando eu cadastro um funcionário com "<campo>" igual a "<valor>" e os demais dados válidos
    Então eu devo ver a mensagem "<mensagem>"
    E o funcionário não deve ser cadastrado

    Exemplos:
      | campo                | valor    | mensagem                           |
      | SIAPE                | 123456   | O SIAPE deve conter 7 dígitos      |
      | SIAPE                | 123A567  | O SIAPE deve conter apenas números |
      | SIAPE                | 7654321  | Este SIAPE já está cadastrado      |
      | SIAPE                |          | O SIAPE é obrigatório              |
      | Nome completo        |          | O nome é obrigatório               |
      | E-mail               |          | O e-mail é obrigatório             |
      | Confirmação de senha | outra456 | A confirmação de senha não confere |

  Cenário: Funcionário que não é administrador não cadastra funcionários (triste)
    Dado que eu estou logado como funcionário
    Quando eu tento acessar o cadastro de funcionários
    Então eu devo ver a mensagem "Acesso permitido apenas para administradores"
    E eu devo ser redirecionado para a página da aplicação de controle
