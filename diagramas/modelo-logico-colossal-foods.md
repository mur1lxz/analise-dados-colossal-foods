# Diagrama lógico relacional — Colossal Foods

> Prévia Mermaid dos relacionamentos entre as 20 tabelas da implementação MySQL. A lista completa de colunas, tipos, PKs, FKs e restrições está em [modelo-logico-colossal-foods-revisado.md](../modelo-logico-colossal-foods-revisado.md).

```mermaid
erDiagram
    CLIENTE ||--o{ PEDIDO : realiza
    FUNCIONARIO ||--o{ PEDIDO : registra
    FUNCIONARIO o|--o{ PEDIDO : prepara
    PEDIDO o|--o{ ITEM_PEDIDO : contem
    PRODUTO ||--o{ ITEM_PEDIDO : aparece
    CATEGORIA ||--o{ PRODUTO : classifica
    PRODUTO ||--o{ PRODUTO_INGREDIENTE : compoe
    INGREDIENTE ||--o{ PRODUTO_INGREDIENTE : utilizado
    FORNECEDOR o|--o{ FORNECEDOR_INGREDIENTE : fornece
    INGREDIENTE o|--o{ FORNECEDOR_INGREDIENTE : fornecido
    PEDIDO ||--o| PAGAMENTO : possui
    FECHAMENTO_CAIXA o|--o{ PAGAMENTO : concilia
    PEDIDO ||--o| ENTREGA : gera
    MOTOBOY ||--o{ ENTREGA : transporta
    AREA_ENTREGA ||--o{ ENTREGA : atende
    FUNCIONARIO o|--o{ FECHAMENTO_CAIXA : registra
    FORNECEDOR ||--o{ COMPRA : fornecedor
    FUNCIONARIO o|--o{ COMPRA : confere
    COMPRA o|--o{ ITEM_COMPRA : contem
    INGREDIENTE ||--o{ ITEM_COMPRA : comprado
    INGREDIENTE ||--o{ MOVIMENTACAO_ESTOQUE : possui
    FUNCIONARIO ||--o{ MOVIMENTACAO_ESTOQUE : registra
    ITEM_COMPRA o|--o{ MOVIMENTACAO_ESTOQUE : origina
    FECHAMENTO_CAIXA ||--o{ CONFERENCIA_CAIXA : possui
    PEDIDO o|--o{ HISTORICO_STATUS_PEDIDO : historico
    FUNCIONARIO ||--o{ HISTORICO_STATUS_PEDIDO : responsavel
    FUNCIONARIO o|--o{ HISTORICO_STATUS_PEDIDO : autoriza
```

## Leitura do diagrama

- `||`: exatamente um registro relacionado.
- `o|`: zero ou um registro relacionado.
- `o{`: zero ou muitos registros relacionados.
- `ITEM_PEDIDO`, `PRODUTO_INGREDIENTE` e `FORNECEDOR_INGREDIENTE` implementam relacionamentos N:N.
- `PRODUTO_INGREDIENTE` possui PK composta (`id_produto`, `id_ingrediente`).
- `FORNECEDOR_INGREDIENTE` possui PK composta (`id_fornecedor`, `id_ingrediente`).
- `PAGAMENTO.id_pedido` e `ENTREGA.id_pedido` são únicos, limitando cada pedido a no máximo um pagamento e uma entrega.

**Importante:** esta prévia Mermaid ajuda a visualizar os relacionamentos no GitHub, mas não substitui o diagrama lógico exportado do brModelo caso a atividade exija essa ferramenta.
