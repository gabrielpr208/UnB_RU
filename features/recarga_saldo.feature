# language: pt
@issue-2
Funcionalidade: Adicionar créditos
  Como estudante
  Eu quero adicionar créditos à minha conta via PIX ou cartão de crédito
  Para que eu tenha saldo suficiente para acessar os restaurantes

  Regras de negócio:
  - PIX: o valor da recarga deve estar entre R$ 1,00 e R$ 1.000,00
  - PIX: o código gerado expira em 1 minuto; o saldo só é creditado ao confirmar o pagamento dentro desse prazo
  - Cartão: o valor da recarga deve estar entre R$ 1,00 e R$ 1000,00
  - Cartão: número com 16 dígitos, validade não vencida e CVV com 3 dígitos; com dados válidos, o saldo é creditado imediatamente

  Contexto:
    Dado que eu estou logado como estudante
    E que meu saldo atual é de R$ 10,00
    E que eu estou na página de adicionar créditos

  # ---------- PIX ----------

  Esquema do Cenário: Gerar código PIX com valor válido (feliz)
    Quando eu solicito uma recarga de "<valor>" via "PIX"
    Então eu devo ver o código PIX para pagamento
    E eu devo ver o botão "Confirmar pagamento"
    E meu saldo deve continuar R$ 10,00

    Exemplos:
      | valor    |
      | 1,00     |
      | 20,00    |
      | 1000,00  |

  Cenário: Confirmar pagamento PIX dentro do prazo (feliz)
    Dado que eu gerei um código PIX de R$ 20,00 há menos de 1 minuto
    Quando eu confirmo o pagamento
    Então eu devo ver a mensagem "Pagamento confirmado"
    E meu saldo deve ser de R$ 30,00

  Cenário: Confirmar pagamento PIX após a expiração (triste)
    Dado que eu gerei um código PIX de R$ 20,00 há mais de 1 minuto
    Quando eu confirmo o pagamento
    Então eu devo ver a mensagem "Código PIX expirado. Gere um novo código"
    E meu saldo deve continuar R$ 10,00

  # ---------- Cartão de crédito ----------

  Esquema do Cenário: Recarga via cartão com dados válidos (feliz)
    Quando eu pago uma recarga de "<valor>" com o cartão "4111111111111111", validade "12/2030" e CVV "123"
    Então eu devo ver a mensagem "Créditos adicionados com sucesso"
    E meu saldo deve ser de R$ <saldo_final>

    Exemplos:
      | valor  | saldo_final |
      | 1,00   | 11,00       |
      | 20,00  | 30,00       |
      | 500,00 | 510,00      |

  Esquema do Cenário: Dados do cartão inválidos (triste)
    Quando eu pago uma recarga de "20,00" com o cartão "<numero>", validade "<validade>" e CVV "<cvv>"
    Então eu devo ver a mensagem "<mensagem>"
    E meu saldo deve continuar R$ 10,00

    Exemplos:
      | numero            | validade | cvv | mensagem                         |
      | 411111111111111   | 12/2030  | 123 | Número do cartão inválido        |
      | 41111111111111111 | 12/2030  | 123 | Número do cartão inválido        |
      | 4111111111111111  | 09/2026  | 123 | Cartão vencido                   |
      | 4111111111111111  | 12/2030  | 12  | CVV inválido                     |
      |                   | 12/2030  | 123 | Preencha todos os dados do cartão |

  # ---------- Valor da recarga ----------

  Esquema do Cenário: Recarga com valor inválido (triste)
    Quando eu solicito uma recarga de "<valor>" via "<forma>"
    Então eu devo ver a mensagem "<mensagem>"
    E meu saldo deve continuar R$ 10,00

    Exemplos:
      | valor   | forma             | mensagem                                |
      | 0,99    | PIX               | O valor mínimo de recarga é R$ 1,00     |
      | 1000,01 | PIX               | O valor máximo de recarga é R$ 1.000,00 |
      | 0,00    | cartão de crédito | O valor mínimo de recarga é R$ 1,00     |
      | 1500,01 | cartão de crédito | O valor máximo de recarga é R$ 1000,00  |
      | abc     | PIX               | Informe um valor numérico válido        |
      |         | cartão de crédito | Informe o valor da recarga              |