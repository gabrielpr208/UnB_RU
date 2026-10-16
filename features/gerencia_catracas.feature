# language: pt
@issue-5
Funcionalidade: Gerenciar catracas
  Como administrador
  Eu quero cadastrar, editar e remover as catracas físicas de cada restaurante
  Para que os funcionários possam selecioná-las na Aplicação de Controle

  Regras de negócio:
  - Toda catraca pertence a um restaurante
  - O identificador é obrigatório e único dentro do mesmo restaurante
  - Uma catraca selecionada por um funcionário na Aplicação de Controle não pode ser removida

  Contexto:
    Dado que eu estou logado como administrador
    E que o restaurante "RU Darcy Ribeiro" possui as catracas "CAT-01" e "CAT-02"
    E que o restaurante "RU Gama" não possui catracas

  # ---------- Cadastrar ----------

  Esquema do Cenário: Cadastrar catraca com dados válidos (feliz)
    Quando eu cadastro a catraca "<identificador>" no restaurante "<restaurante>"
    Então eu devo ver a mensagem "Catraca cadastrada com sucesso"
    E a catraca "<identificador>" deve estar disponível para seleção na Aplicação de Controle do "<restaurante>"

    Exemplos:
      | identificador | restaurante      |
      | CAT-03        | RU Darcy Ribeiro |
      | CAT-01        | RU Gama          |

  Esquema do Cenário: Cadastrar catraca com dados inválidos (triste)
    Quando eu cadastro a catraca "<identificador>" no restaurante "<restaurante>"
    Então eu devo ver a mensagem "<mensagem>"
    E a catraca não deve ser cadastrada

    Exemplos:
      | identificador | restaurante      | mensagem                                                 |
      |               | RU Darcy Ribeiro | O identificador é obrigatório                            |
      | CAT-01        | RU Darcy Ribeiro | Já existe uma catraca com este identificador neste restaurante |
      | CAT-03        |                  | Selecione um restaurante                                 |

  # ---------- Editar ----------

  Cenário: Editar identificador da catraca (feliz)
    Quando eu altero o identificador da catraca "CAT-01" do "RU Darcy Ribeiro" para "CAT-10"
    Então eu devo ver a mensagem "Catraca atualizada com sucesso"
    E a catraca "CAT-10" deve estar disponível para seleção na Aplicação de Controle do "RU Darcy Ribeiro"

  Esquema do Cenário: Editar catraca com dados inválidos (triste)
    Quando eu altero o identificador da catraca "CAT-01" do "RU Darcy Ribeiro" para "<novo_identificador>"
    Então eu devo ver a mensagem "<mensagem>"
    E a catraca "CAT-01" deve continuar com o mesmo identificador

    Exemplos:
      | novo_identificador | mensagem                                                       |
      |                    | O identificador é obrigatório                                  |
      | CAT-02             | Já existe uma catraca com este identificador neste restaurante |

  # ---------- Remover ----------

  Cenário: Remover catraca que não está em uso (feliz)
    Quando eu removo a catraca "CAT-02" do "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Catraca removida com sucesso"
    E a catraca "CAT-02" não deve estar disponível para seleção na Aplicação de Controle do "RU Darcy Ribeiro"

  Cenário: Remover catraca em uso por um funcionário (triste)
    Dado que um funcionário selecionou a catraca "CAT-01" do "RU Darcy Ribeiro" na Aplicação de Controle
    Quando eu removo a catraca "CAT-01" do "RU Darcy Ribeiro"
    Então eu devo ver a mensagem "Não é possível remover uma catraca em uso"
    E a catraca "CAT-01" deve continuar cadastrada