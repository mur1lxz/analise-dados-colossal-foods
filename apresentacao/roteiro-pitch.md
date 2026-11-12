# Roteiro do pitch — Colossal Foods (8 minutos)

Ordem exigida pelo roteiro da Entrega 2. Slides limpos: um título, uma imagem ou número grande, no máximo três tópicos curtos. Nada de ler blocos de texto. Os dois integrantes participam e ambos precisam dominar o modelo lógico para a defesa (cada pergunta é respondida só por quem foi chamado).

| # | Slide | Tempo | Quem | Conteúdo |
|---|---|---|---|---|
| 1 | Capa | 0:15 | Murilo | “Colossal Foods — gestão de informações para uma hamburgueria”; nomes e RGMs |
| 2 | Contexto e problema | 1:00 | Murilo | Foto da fachada; 4 funcionários + 1 motoboy; 300+ pedidos por semana; cardápio terceirizado sem controle interno; P1 (atraso do delivery) e P2 (preço × custo) em destaque, P3–P7 em uma linha |
| 3 | Solução proposta | 0:45 | Murilo | Um banco único para pedidos, delivery, estoque, compras e caixa; DER revisado em miniatura |
| 4 | Modelo lógico | 1:15 | Kauê | Diagrama do modelo lógico; 20 tabelas, 27 FKs; destacar ITEM_PEDIDO (preço praticado), HISTORICO_STATUS_PEDIDO (tempos) e MOVIMENTACAO_ESTOQUE (saldo calculado) |
| 5 | SQL rodando (demo ao vivo) | 1:15 | Kauê | Executar o script no Workbench; mostrar as 20 tabelas; rodar T01 (produto indisponível) e T07 (compra sem nota) e mostrar o banco recusando |
| 6 | Consultas gerenciais (demo) | 1:15 | Murilo | G12 (% de deliveries em até 45 min — cai no fim de semana), G13 (picos por hora), G15 (CMV por produto), G04 (refrigerante e chocolate abaixo do mínimo) |
| 7 | Auditoria (demo) | 0:45 | Kauê | A08 encontra as duas quebras de caixa; A01–A07 e A09–A13 retornam vazio = regras respeitadas |
| 8 | Potencial para BI e IA | 0:45 | Kauê | Esboço de painel (tempo de delivery, ticket médio, CMV, estoque); previsão de demanda por hora e sugestão de compra |
| 9 | Benefícios para a decisão | 0:45 | Murilo | Escalar o motoboy nos horários de pico; reajustar preço com base no CMV; comprar antes de faltar; fechar o caixa com diferença identificada |

Total: 8:00. Ensaiar com cronômetro; deixar as consultas da demo abertas em abas do Workbench, já com o banco criado, para não depender do tempo de carga.

## Perguntas prováveis na defesa

- Por que `preco_unitario` em ITEM_PEDIDO não viola a 3FN? (valor histórico da venda — RN07)
- Por que PAGAMENTO e ENTREGA têm `id_pedido` UNIQUE e não o contrário? (1:1 com lado opcional)
- Por que o saldo de estoque não é uma coluna? (derivado; histórico auditável — RN22)
- Por que ITEM_PEDIDO tem PK própria e PRODUTO_INGREDIENTE tem PK composta?
- Como o banco impede delivery finalizado sem entrega? (trigger `trg_pedido_bu` — RN14)
- O que é uma entidade associativa no DER? (ITEM_COMPRA, ligada a MOVIMENTACAO_ESTOQUE)
- De onde vêm os números da massa? (volume informado: 30–50 / 60–90 pedidos por dia)

## Lembretes

- Traje corporativo (sem boné, bermuda, chinelo, camisa de time ou roupa esportiva).
- Não apresentar dados fictícios (taxas, mínimos, metas) como dados reais da loja.
