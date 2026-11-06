# Modelo lógico relacional — Colossal Foods

Diagrama derivado diretamente das definições de tabelas, chaves primárias, chaves estrangeiras e restrições UNIQUE do [script SQL](../script.sql). São apresentadas as 20 tabelas e os 27 vínculos de chave estrangeira implementados.

## Diagrama

```mermaid
erDiagram
  FUNCIONARIO ||--o{ FECHAMENTO_CAIXA : "registra"
  FORNECEDOR ||--o{ COMPRA : "fornece"
  FUNCIONARIO ||--o{ COMPRA : "confere"
  CATEGORIA ||--o{ PRODUTO : "classifica"
  CLIENTE ||--o{ PEDIDO : "realiza"
  FUNCIONARIO ||--o{ PEDIDO : "registra"
  FUNCIONARIO ||--o{ PEDIDO : "prepara"
  COMPRA ||--o{ ITEM_COMPRA : "contém"
  INGREDIENTE ||--o{ ITEM_COMPRA : "utiliza"
  PRODUTO ||--o| PRODUTO_INGREDIENTE : "inclui"
  INGREDIENTE ||--o| PRODUTO_INGREDIENTE : "utiliza"
  FORNECEDOR ||--o| FORNECEDOR_INGREDIENTE : "fornece"
  INGREDIENTE ||--o| FORNECEDOR_INGREDIENTE : "utiliza"
  PEDIDO ||--o{ ITEM_PEDIDO : "vincula"
  PRODUTO ||--o{ ITEM_PEDIDO : "inclui"
  INGREDIENTE ||--o{ MOVIMENTACAO_ESTOQUE : "utiliza"
  FUNCIONARIO ||--o{ MOVIMENTACAO_ESTOQUE : "registra"
  ITEM_COMPRA ||--o{ MOVIMENTACAO_ESTOQUE : "origina"
  PEDIDO ||--o| PAGAMENTO : "vincula"
  FECHAMENTO_CAIXA ||--o{ PAGAMENTO : "concilia"
  PEDIDO ||--o| ENTREGA : "vincula"
  MOTOBOY ||--o{ ENTREGA : "transporta"
  AREA_ENTREGA ||--o{ ENTREGA : "atende"
  FECHAMENTO_CAIXA ||--o{ CONFERENCIA_CAIXA : "concilia"
  PEDIDO ||--o{ HISTORICO_STATUS_PEDIDO : "vincula"
  FUNCIONARIO ||--o{ HISTORICO_STATUS_PEDIDO : "registra"
  FUNCIONARIO ||--o{ HISTORICO_STATUS_PEDIDO : "autoriza"
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
- **PK, FK**: atributo que é simultaneamente parte da chave primária e chave estrangeira.
- **||**: exatamente um registro relacionado.
- **o|**: zero ou um.
- **o{**: zero ou muitos.

## Observações
- `PRODUTO_INGREDIENTE`: chave primária composta por `id_produto` e `id_ingrediente`; ambos também são FKs.
- `FORNECEDOR_INGREDIENTE`: chave primária composta por `id_fornecedor` e `id_ingrediente`; ambos também são FKs.
- `ITEM_PEDIDO` liga pedidos aos produtos.
- `PAGAMENTO.id_pedido` e `ENTREGA.id_pedido` são únicos, limitando cada pedido a no máximo um pagamento e uma entrega.
- A cardinalidade mínima do lado da tabela dependente considera se a FK aceita NULL; a cardinalidade máxima considera as restrições UNIQUE.
- Regras de negócio adicionais, como exigir itens antes do pagamento e validar delivery, estão implementadas por triggers e consultas de auditoria no SQL.

