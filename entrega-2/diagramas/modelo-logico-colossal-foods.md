# Modelo lógico relacional — Colossal Foods

Diagrama gerado a partir das definições reais de `CREATE TABLE` e das chaves estrangeiras do arquivo [script.sql](../script.sql). Contém as 20 tabelas, atributos e relacionamentos implementados.

## Diagrama completo

```mermaid
erDiagram
  FUNCIONARIO o|--o{ FECHAMENTO_CAIXA : "registra"
  FORNECEDOR o|--o{ COMPRA : "fornece"
  FUNCIONARIO o|--o{ COMPRA : "confere"
  CATEGORIA o|--o{ PRODUTO : "classifica"
  CLIENTE o|--o{ PEDIDO : "realiza"
  FUNCIONARIO o|--o{ PEDIDO : "registra"
  FUNCIONARIO o|--o{ PEDIDO : "prepara"
  COMPRA o|--o| ITEM_COMPRA : "contém"
  INGREDIENTE o|--o| ITEM_COMPRA : "utiliza"
  PRODUTO o|--o{ PRODUTO_INGREDIENTE : "inclui"
  INGREDIENTE o|--o{ PRODUTO_INGREDIENTE : "utiliza"
  FORNECEDOR o|--o{ FORNECEDOR_INGREDIENTE : "fornece"
  INGREDIENTE o|--o{ FORNECEDOR_INGREDIENTE : "utiliza"
  PEDIDO o|--o{ ITEM_PEDIDO : "vincula"
  PRODUTO o|--o{ ITEM_PEDIDO : "inclui"
  INGREDIENTE o|--o{ MOVIMENTACAO_ESTOQUE : "utiliza"
  FUNCIONARIO o|--o{ MOVIMENTACAO_ESTOQUE : "registra"
  ITEM_COMPRA o|--o{ MOVIMENTACAO_ESTOQUE : "origina"
  PEDIDO o|--o| PAGAMENTO : "vincula"
  FECHAMENTO_CAIXA o|--o{ PAGAMENTO : "concilia"
  PEDIDO o|--o| ENTREGA : "vincula"
  MOTOBOY o|--o{ ENTREGA : "transporta"
  AREA_ENTREGA o|--o{ ENTREGA : "atende"
  FECHAMENTO_CAIXA o|--o| CONFERENCIA_CAIXA : "concilia"
  PEDIDO o|--o{ HISTORICO_STATUS_PEDIDO : "vincula"
  FUNCIONARIO o|--o{ HISTORICO_STATUS_PEDIDO : "registra"
  FUNCIONARIO o|--o{ HISTORICO_STATUS_PEDIDO : "autoriza"
  CATEGORIA {
    BIGINT id_categoria PK
    VARCHAR(80) nome
    VARCHAR(255) descricao
  }
  CLIENTE {
    BIGINT id_cliente PK
    VARCHAR(120) nome
    VARCHAR(20) telefone
  }
  FORNECEDOR {
    BIGINT id_fornecedor PK
    VARCHAR(150) nome
    VARCHAR(20) telefone
    VARCHAR(150) email
  }
  MOTOBOY {
    BIGINT id_motoboy PK
    VARCHAR(120) nome
    VARCHAR(20) telefone
  }
  FUNCIONARIO {
    BIGINT id_funcionario PK
    VARCHAR(120) nome
    VARCHAR(30) funcao
    VARCHAR(20) telefone
    TINYINT(1) ativo
  }
  INGREDIENTE {
    BIGINT id_ingrediente PK
    VARCHAR(120) nome
    VARCHAR(20) unidade_medida
    DECIMAL(12,3) estoque_minimo
  }
  AREA_ENTREGA {
    BIGINT id_area_entrega PK
    VARCHAR(100) bairro
    DECIMAL(10,2) taxa_padrao
    TINYINT(1) ativo
  }
  FECHAMENTO_CAIXA {
    BIGINT id_fechamento PK
    BIGINT id_funcionario_responsavel FK
    DATETIME data_hora_inicio
    DATETIME data_hora_fim
    TEXT observacao
  }
  COMPRA {
    BIGINT id_compra PK
    BIGINT id_fornecedor FK
    BIGINT id_funcionario_conferente FK
    DATETIME data_pedido
    DATETIME data_recebimento
    VARCHAR(50) numero_nota_fiscal
    VARCHAR(20) status_compra
    VARCHAR(20) resultado_conferencia
    TEXT observacao_conferencia
  }
  PRODUTO {
    BIGINT id_produto PK
    BIGINT id_categoria FK
    VARCHAR(120) nome
    TEXT descricao
    DECIMAL(10,2) preco
    TINYINT(1) disponivel
  }
  PEDIDO {
    BIGINT id_pedido PK
    BIGINT id_cliente FK
    BIGINT id_funcionario_registro FK
    BIGINT id_funcionario_preparo FK
    DATETIME data_hora
    VARCHAR(10) tipo_pedido
    VARCHAR(20) status
  }
  ITEM_COMPRA {
    BIGINT id_item_compra PK
    BIGINT id_compra FK
    BIGINT id_ingrediente FK
    DECIMAL(12,3) quantidade_solicitada
    DECIMAL(12,3) quantidade_recebida
    DECIMAL(10,2) custo_unitario
  }
  PRODUTO_INGREDIENTE {
    BIGINT id_produto PK,FK
    BIGINT id_ingrediente PK,FK
    DECIMAL(12,3) quantidade_utilizada
  }
  FORNECEDOR_INGREDIENTE {
    BIGINT id_fornecedor PK,FK
    BIGINT id_ingrediente PK,FK
  }
  ITEM_PEDIDO {
    BIGINT id_item_pedido PK
    BIGINT id_pedido FK
    BIGINT id_produto FK
    INT quantidade
    DECIMAL(10,2) preco_unitario
    VARCHAR(255) observacao
  }
  MOVIMENTACAO_ESTOQUE {
    BIGINT id_movimentacao PK
    BIGINT id_ingrediente FK
    BIGINT id_funcionario FK
    BIGINT id_item_compra FK
    VARCHAR(20) tipo_movimentacao
    DECIMAL(12,3) quantidade
    DATETIME data_hora
    VARCHAR(255) motivo
  }
  PAGAMENTO {
    BIGINT id_pagamento PK
    BIGINT id_pedido FK
    BIGINT id_fechamento FK
    VARCHAR(20) forma_pagamento
    DECIMAL(10,2) valor
    DATETIME data_hora
  }
  ENTREGA {
    BIGINT id_entrega PK
    BIGINT id_pedido FK
    BIGINT id_motoboy FK
    BIGINT id_area_entrega FK
    VARCHAR(150) logradouro
    VARCHAR(20) numero
    VARCHAR(100) complemento
    VARCHAR(9) cep
    DECIMAL(10,2) taxa_entrega_aplicada
    DATETIME data_hora_saida
    DATETIME data_hora_entrega
    VARCHAR(20) status
  }
  CONFERENCIA_CAIXA {
    BIGINT id_conferencia PK
    BIGINT id_fechamento FK
    VARCHAR(20) forma_pagamento
    DECIMAL(10,2) valor_contado
  }
  HISTORICO_STATUS_PEDIDO {
    BIGINT id_historico PK
    BIGINT id_pedido FK
    BIGINT id_funcionario_responsavel FK
    BIGINT id_funcionario_autorizador FK
    VARCHAR(20) status_anterior
    VARCHAR(20) status_novo
    DATETIME data_hora
    VARCHAR(255) motivo
  }
```

## Legenda
- **PK**: chave primária.
- **FK**: chave estrangeira.
- **PK, FK**: atributo que participa da chave primária e também referencia outra tabela.
- **||**: exatamente um.
- **o|**: zero ou um.
- **o{**: zero ou muitos.

## Observações importantes
- `PRODUTO_INGREDIENTE` tem chave primária composta por `id_produto` e `id_ingrediente`.
- `FORNECEDOR_INGREDIENTE` tem chave primária composta por `id_fornecedor` e `id_ingrediente`.
- `ITEM_PEDIDO` representa os produtos que compõem cada pedido.
- `PAGAMENTO.id_pedido` e `ENTREGA.id_pedido` são únicos: cada pedido pode ter no máximo um pagamento e uma entrega.
- Campos opcionais permanecem identificados como FK; a cardinalidade do relacionamento considera a possibilidade de nulo no banco.
- O diagrama representa o esquema implementado no MySQL. Regras de negócio adicionais estão documentadas no [modelo lógico relacional](../modelo-logico-relacional.md) e no script SQL.

