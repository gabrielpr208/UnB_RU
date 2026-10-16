# language: pt
@issue-8.1
Funcionalidade: Gerenciar restaurantes
  Como administrador
  Eu quero cadastrar, editar e remover restaurantes
  Para que os funcionários possam selecioná-los na Aplicação de Controle

  Regras de negócio:
  - Nome e campus são obrigatórios
  - O nome deve ter entre 3 e 50 caracteres e ser único
  - O campus deve ser Darcy Ribeiro, Gama, Ceilândia ou Planaltina
  - Um restaurante com catracas cadastradas não pode ser removido

  Contexto:
    Dado que eu estou logado como administrador
    E que existem os seguintes restaurantes:
      | nome             | campus        |
      | RU Darcy Ribeiro | Darcy Ribeiro |
      | RU Gama          | Gama          |

  # ---------- Cadastrar ----------

  Esquema do Cenário: Cadastrar restaurante com dados válidos (feliz)
    Quando eu cadastro o restaurante "<nome>" no campus "<campus>"
    Então eu devo ver a mensagem "Restaurante cadastrado com sucesso"
    E o restaurante "<nome>" deve aparecer na lista de restaurantes

    Exemplos:
      | nome                                               | campus     |
      | FUP                                                | Planaltina |
      | RU FCE                                             | Ceilândia  |
      | Restaurante Universitário do Campus Planaltina 001 | Planaltina |

  Esquema do Cenário: Cadastrar restaurante com dados inválidos (triste)
    Quando eu cadastro o restaurante "<nome>" no campus "<campus>"
    Então eu devo ver a mensagem "<mensagem>"
    E o restaurante não deve ser cadastrado

    Exemplos:
      | nome                                                | campus     | mensagem                                 |
      |                                                     | Ceilândia  | O nome é obrigatório                     |
      | RU                                                  | Ceilândia  | O nome deve ter entre 3 e 50 caracteres  |
      | Restaurante Universitário do Campus Planaltina 0001 | Planaltina | O nome deve ter entre 3 e 50 caracteres  |
      | RU FCE                                              |            | O campus é obrigatório                   |
      | RU Taguatinga                                       | Taguatinga | Campus inválido                          |
      | RU Gama                                             | Gama       | Já existe um restaurante com este nome   |

  # ---------- Editar ----------

  Cenário: Editar restaurante com dados válidos (feliz)
    Quando eu altero o nome do restaurante "RU Darcy Ribeiro" para "RU Central"
    Então eu devo ver a mensagem "Restaurante atualizado com sucesso"
    E o restaurante "RU Central" deve aparecer na lista de restaurantes

  Esquema do Cenário: Editar restaurante com dados inválidos (triste)
    Quando eu altero o nome do restaurante "RU Gama" para "<novo_nome>"
    Então eu devo ver a mensagem "<mensagem>"
    E o restaurante "RU Gama" deve continuar com o mesmo nome

    Exemplos:
      | novo_nome        | mensagem                                |
      |                  | O nome é obrigatório                    |
      | RU               | O nome deve ter entre 3 e 50 caracteres |
      | RU Darcy Ribeiro | Já existe um restaurante com este nome  |

  # ---------- Remover ----------

  Cenário: Remover restaurante sem catracas (feliz)
    Quando eu removo o restaurante "RU Gama"
    Então eu devo ver a mensagem "Restaurante removido com sucesso"
    E o restaurante "RU Gama" não deve aparecer na lista de restaurantes

  Cenário: Remover restaurante com catracas cadastradas (triste)
    Dado que o restaurante "RU Darcy Ribeiro" possui a catraca "CAT-01"
    Quando eu removo o restaurante "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Não é possível remover um restaurante com catracas cadastradas"
    E o restaurante "RU Darcy Ribeiro" deve aparecer na lista de restaurantes