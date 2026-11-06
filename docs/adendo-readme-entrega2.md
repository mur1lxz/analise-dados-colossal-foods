# Adendo para integrar ao README.md — Entrega 2

> Este conteúdo deve ser incorporado ao `README.md` da raiz da branch `main`. Este arquivo é apenas um texto de apoio; não substitui o README exigido pelo professor.

## Problemas e necessidades de gestão de informações

Os problemas abaixo foram numerados para permitir a rastreabilidade entre a caracterização da organização e as consultas gerenciais do script SQL. P1 e P2 correspondem às necessidades já descritas no projeto. P3 a P7 ampliam a cobertura dos processos revisados após a correção da Entrega 1; devem ser apresentados como necessidades de informação do sistema, e não como reclamações literais do responsável sem confirmação em entrevista.

- **P1 — Acompanhamento do tempo de expedição do delivery:** estruturar os horários de recebimento, preparo, saída e conclusão da entrega para calcular tempos médios e identificar atrasos.
- **P2 — Histórico de preços e custos:** preservar o preço praticado em cada venda e os custos unitários de aquisição dos ingredientes para comparar variações ao longo do tempo.
- **P3 — Acompanhamento manual do estoque:** registrar entradas, saídas e ajustes de ingredientes, calcular o saldo pelas movimentações e identificar itens abaixo do estoque mínimo quando esse limite estiver definido.
- **P4 — Acompanhamento de cancelamentos:** manter o histórico de status, motivo, data/hora e responsável pelo cancelamento para medir frequência e analisar ocorrências.
- **P5 — Conferência diária do caixa:** comparar os valores de pagamentos registrados por forma de pagamento com os valores apurados no fechamento coletivo do expediente.
- **P6 — Rastreabilidade de compras e fornecedores:** registrar fornecedor, data da compra, ingredientes, quantidades solicitadas/recebidas, nota fiscal e custo unitário para acompanhar o abastecimento e a variação de custos.
- **P7 — Controle das áreas de delivery:** registrar os bairros/áreas atendidos e a taxa padrão correspondente, preservando no pedido de entrega a taxa efetivamente aplicada.

## Requisitos funcionais complementares

- **RF14 — Cadastro de funcionários:** o sistema deve permitir registrar funcionário com nome, função, telefone e situação (ativo/inativo), vinculando o funcionário aos pedidos que registra/prepara, às movimentações de estoque, aos recebimentos e aos fechamentos quando identificado.
- **RF15 — Registro de compras:** o sistema deve permitir registrar uma compra com fornecedor, data do pedido, status e observações, além de seus itens com ingrediente, quantidade solicitada, quantidade recebida e custo unitário.
- **RF16 — Recebimento de ingredientes:** o sistema deve registrar data de recebimento, número da nota fiscal, funcionário conferente e resultado da conferência, mantendo a compra pendente até que os itens e as quantidades recebidas sejam informados.
- **RF17 — Movimentação manual de estoque:** o sistema deve permitir registrar movimentações por ingrediente, tipo (entrada, saída, ajuste de entrada ou ajuste de saída), quantidade, data/hora, funcionário responsável, motivo e, quando aplicável, o item de compra que originou a entrada. Nesta versão não há baixa automática por venda.
- **RF18 — Áreas de entrega e taxas:** o sistema deve permitir cadastrar bairro/área atendida, taxa padrão e situação ativa/inativa, registrando na entrega a taxa efetivamente aplicada.
- **RF19 — Fechamento de caixa:** o sistema deve registrar o fechamento com período, data/hora e responsável pelo lançamento, além dos valores contados por forma de pagamento, para comparação com os pagamentos associados ao fechamento.
- **RF20 — Histórico de status e cancelamentos:** o sistema deve registrar cada mudança de status do pedido com status anterior, status novo, data/hora e funcionário responsável; para cancelamentos, deve guardar a justificativa e, quando exigido pela RN17, o funcionário autorizador.

## Ajuste do requisito RF06 e da regra RN08

Substituir a redação de RF06 por:

**RF06 —** O sistema deve calcular o valor total do pedido pela soma de `quantidade × preco_unitario` dos itens; quando o pedido for `DELIVERY`, deve acrescentar a taxa registrada em `ENTREGA.taxa_entrega_aplicada`.

Complementar a RN08 para deixar explícito que o valor pago deve corresponder ao total dos itens **mais a taxa de entrega quando houver delivery**, em conjunto com a RN19. O valor total permanece derivado e não é armazenado como coluna redundante em PEDIDO.

## Regras de negócio complementares

- **RN21 —** Uma compra somente pode passar para o status `RECEBIDA` quando possuir número de nota fiscal, data de recebimento, funcionário conferente, resultado de conferência diferente de `PENDENTE` e ao menos um item com quantidade recebida maior que zero.
- **RN22 —** O saldo de cada ingrediente é calculado pela soma das movimentações `ENTRADA` e `AJUSTE_ENTRADA`, menos `SAIDA` e `AJUSTE_SAIDA`. Saldo negativo representa inconsistência que deve ser identificada e analisada.
- **RN23 —** Quando uma movimentação de estoque estiver vinculada a um item de compra, ela deve ser do tipo `ENTRADA`, referir-se ao mesmo ingrediente do item e não pode fazer a quantidade total lançada superar a quantidade recebida.
- **RN24 —** Toda alteração de status de um pedido deve gerar um evento em `HISTORICO_STATUS_PEDIDO`, com data/hora e funcionário responsável; o status atual do pedido deve corresponder ao último evento registrado.

## Rastreabilidade entre problemas e consultas gerenciais

| Problema | Tabelas principais | Consulta no `docs/script.sql` |
|---|---|---|
| P1 — Tempo de expedição e delivery | PEDIDO, HISTORICO_STATUS_PEDIDO, ENTREGA | G01 |
| P2 — Histórico de preço e custo | PRODUTO, PEDIDO, ITEM_PEDIDO, COMPRA, ITEM_COMPRA, INGREDIENTE | G02 e G03 |
| P3 — Estoque de ingredientes | INGREDIENTE, MOVIMENTACAO_ESTOQUE | G04 |
| P4 — Cancelamentos | PEDIDO, HISTORICO_STATUS_PEDIDO | G05 |
| P5 — Fechamento de caixa | PAGAMENTO, FECHAMENTO_CAIXA, CONFERENCIA_CAIXA | G06 |
| P6 — Compras e fornecedores | FORNECEDOR, COMPRA, ITEM_COMPRA, INGREDIENTE | G07 |
| P7 — Áreas e taxas de delivery | AREA_ENTREGA, ENTREGA | G08 |

## Rastreabilidade das consultas de auditoria

| Consulta | Regra verificada |
|---|---|
| A01 | RN02 — todo pedido deve conter ao menos um produto |
| A02 | RN08 e RN19 — pagamento igual ao total dos itens mais taxa de delivery |
| A03 | RN10 e RN11 — retirada sem entrega; delivery ativo com entrega |
| A04 | RN12 — toda entrega possui motoboy |
| A05 | RN22 — saldo de estoque não negativo |
| A06 | RN23 — movimentação de entrada coerente com o item de compra |
| A07 | RN17 — cancelamento com justificativa e autorização quando necessária |
| A08 | RN18 — pagamento por forma de pagamento conciliado com o valor contado |
| A09 | RN24 — status atual coerente com o último evento do histórico |
| A10 | RN20 e RN21 — recebimento conferido e documentado |
| A11 | RN18 — fechamento com registros de conferência |
| A12 | RN14 — delivery só finaliza após entrega concluída |

## Observações sobre a massa de dados

A massa do script é integralmente fictícia. Os 138 pedidos demonstrativos foram distribuídos em três dias (34, 39 e 65 pedidos), quantidades compatíveis com as estimativas de movimento descritas no README (30–50 pedidos em dias de semana e 60–90 aos finais de semana). Nomes, telefones, e-mails, endereços, notas fiscais, preços, custos, taxas e movimentações são dados ilustrativos, não registros reais da hamburgueria.

Somente Jardim Arantes está identificado no material atual como área de atendimento. Os outros dois bairros da massa de dados são identificados como exemplos fictícios. Os estoques mínimos e as taxas usadas na demonstração também precisam ser confirmados com o responsável antes de serem descritos como parâmetros reais.

A escala individual dos funcionários não foi modelada porque o material levantado informa a composição geral da equipe, mas não confirma uma escala por pessoa. O sistema registra o funcionário responsável por cada operação quando essa informação estiver disponível.