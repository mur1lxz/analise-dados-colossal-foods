# Como executar e validar o script SQL — Colossal Foods

## Requisitos

- MySQL Server 8.0.16 ou superior (CHECK constraints efetivas) e MySQL Workbench.
- Usuário com permissão para criar banco, tabelas e triggers.

## Executar do zero

1. Abra `docs/script.sql` no MySQL Workbench.
2. Se o banco já existir de uma execução anterior, rode antes `DROP DATABASE IF EXISTS colossal_foods;` (apaga tudo nesse banco).
3. Execute o arquivo inteiro (ícone de raio). O script usa `DELIMITER $$` para as triggers.
4. Atualize os schemas: o banco `colossal_foods` deve ter **20 tabelas** e **11 triggers** (`SHOW TRIGGERS FROM colossal_foods;`).
5. Confira a carga: `SELECT COUNT(*) FROM PEDIDO;` → **690**; `SELECT COUNT(*) FROM ITEM_PEDIDO;` → **1497**.

O `UPDATE` da seção 5 usa faixa de chave primária (`id_compra BETWEEN 1 AND 24`), compatível com o *safe update mode* do Workbench.

## Resultados esperados

| Consulta | O que deve aparecer |
|---|---|
| G01 | 14 dias com tempo médio até pronto (≈ 18–24 min) e em rota |
| G02 | Bacon Burger e Batata Frita com menor preço praticado < maior (reajuste em 02/11); Colossal Burger com preço atual 31,90 e praticado 29,90 |
| G03 | Custo por ingrediente em 2026-10 e 2026-11 |
| G04 | **2 linhas**: Refrigerante lata e Chocolate em pó abaixo do mínimo |
| G05 | Cancelamentos por dia (18 no total) |
| G06 | Conferência por forma; duas linhas com situação DIVERGENCIA |
| G07 / G08 | Compras por fornecedor; entregas por área (Bairro Exemplo 03, inativo, com 0) |
| G09–G11 | Ticket médio, faturamento semanal por forma, mix de produtos (Milk-shake Morango com 0 vendas) |
| G12 | % de deliveries em até 45 min por dia — alto nos dias úteis, baixo nos fins de semana |
| G13 | Pedidos e tempo de delivery por hora, semana × fim de semana |
| G14 | 150 clientes; 20 sem pedido finalizado |
| G15 | CMV teórico por produto |
| A01–A07, A09–A13 | **0 linhas** (regras respeitadas) |
| A08 | **2 linhas, de propósito**: fechamento 4 (falta de R$ 5,00 em dinheiro) e fechamento 12 (sobra de R$ 2,00) |

## Testes das triggers (T01–T10)

No fim do script há dez comandos comentados. Descomente e execute **um por vez**: cada um deve ser recusado com a mensagem indicada (ex.: T01 → `RN05: produto indisponivel nao pode entrar em novo pedido`). Depois do T04/T05, rode a linha de limpeza indicada. Registre os resultados no README (seção 3).

## Regerar a massa, os diagramas e o dicionário

- Massa: `python3 docs/gerador-massa/gerar_massa.py > massa.sql` (substitui a seção 3 do script).
- Diagramas: `python3 docs/diagramas/gerar_diagramas.py` (requer Graphviz).
- Dicionário: `python3 docs/gerador-dicionario/gerar_dicionario.py`.

Todos os dados são fictícios; taxas, bairros, estoques mínimos e metas são ilustrativos.
