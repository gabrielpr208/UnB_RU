# language: pt
@issue-4
Funcionalidade: Gerenciar funcionários
  Como administrador
  Eu quero editar e remover funcionários
  Para manter atualizado quem entra na Aplicação de Controle e com qual perfil

  Regras de negócio:
  - Só o administrador edita e remove funcionários
  - Na edição valem as mesmas regras do cadastro; a senha só muda se uma nova for informada
  - O administrador não pode tirar o próprio acesso de administrador nem remover a própria conta
  - O funcionário removido não entra mais na Aplicação de Controle, e a catraca que ele operava fica livre

  Contexto:
    Dado que eu estou logado como administrador
    E que existem os seguintes funcionários:
      | nome         | siape   | email          | perfil        |
      | José Pereira | 1234567 | jose@unb.br    | Funcionário   |
      | Bruno Alves  | 2223334 | bruno@unb.br   | Administrador |

  # ---------- Editar ----------

  Cenário: Editar os dados do funcionário sem trocar a senha (feliz)
    Quando eu altero o nome do funcionário "José Pereira" para "José da Silva"
    Então eu devo ver a mensagem "Funcionário atualizado com sucesso"
    E o funcionário com SIAPE "1234567" deve aparecer na lista com o nome "José da Silva"
    E o funcionário com SIAPE "1234567" deve conseguir entrar com a senha "senha123"

  Esquema do Cenário: Alterar o perfil do funcionário (feliz)
    Quando eu altero o perfil do funcionário "<nome>" para "<perfil>"
    Então eu devo ver a mensagem "Funcionário atualizado com sucesso"
    E o funcionário com SIAPE "<siape>" deve aparecer na lista com o perfil "<perfil>"

    Exemplos:
      | nome         | siape   | perfil        |
      | José Pereira | 1234567 | Administrador |
      | Bruno Alves  | 2223334 | Funcionário   |

  Cenário: Trocar a senha do funcionário (feliz)
    Quando eu altero a senha do funcionário "José Pereira" para "nova1234"
    Então eu devo ver a mensagem "Funcionário atualizado com sucesso"
    E o funcionário com SIAPE "1234567" deve conseguir entrar com a senha "nova1234"

  Esquema do Cenário: Editar funcionário com dados inválidos (triste)
    Quando eu altero o funcionário "José Pereira" com "<campo>" igual a "<valor>"
    Então eu devo ver a mensagem "<mensagem>"
    E o funcionário com SIAPE "1234567" deve continuar com os mesmos dados

    Exemplos:
      | campo         | valor        | mensagem                                |
      | SIAPE         | 2223334      | Este SIAPE já está cadastrado           |
      | SIAPE         | 123          | O SIAPE deve conter 7 dígitos           |
      | Nome completo |              | O nome é obrigatório                    |
      | E-mail        | bruno@unb.br | Este e-mail já está cadastrado          |
      | Nova senha    | 12345        | A senha deve ter no mínimo 6 caracteres |

  Cenário: Administrador tenta tirar o próprio acesso de administrador (triste)
    Quando eu altero o perfil do funcionário "Ana Lima" para "Funcionário"
    Então eu devo ver a mensagem "Você não pode tirar o seu próprio acesso de administrador"
    E o funcionário com SIAPE "7654321" deve aparecer na lista com o perfil "Administrador"

  # ---------- Remover ----------

  Cenário: Remover funcionário (feliz)
    Quando eu removo o funcionário "José Pereira"
    Então eu devo ver a mensagem "Funcionário removido com sucesso"
    E o funcionário "José Pereira" não deve aparecer na lista de funcionários
    E o funcionário com SIAPE "1234567" não deve conseguir entrar com a senha "senha123"

  Cenário: Remover funcionário que está operando uma catraca (feliz)
    Dado que o funcionário "José Pereira" está operando a catraca "01" do "RU Darcy Ribeiro"
    Quando eu removo o funcionário "José Pereira"
    Então eu devo ver a mensagem "Funcionário removido com sucesso"
    E a catraca "01" do "RU Darcy Ribeiro" deve estar livre

  Cenário: Administrador não tem a opção de remover a própria conta (triste)
    Então eu não devo ter a opção de remover o funcionário "Ana Lima"
    Mas eu devo ter a opção de remover o funcionário "José Pereira"
