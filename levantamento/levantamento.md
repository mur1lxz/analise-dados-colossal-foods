# Levantamento de requisitos — Colossal Foods

Este documento organiza o que o grupo levantou sobre a Colossal Foods para a modelagem do banco de dados. Ele separa três origens de informação, porque elas têm pesos diferentes como evidência:

- **[E] Entrevista** — informado pela equipe/responsável durante a visita.
- **[O] Observação** — visto pelo grupo no local, durante a rotina.
- **[P] Pesquisa** — processo ou regra típica de hamburgueria, levantado por pesquisa (inclusive com apoio de IA — ver seção 6 do README) e que ainda precisa ser confirmado com o responsável.

---

## 1. Organização

| Dado | Informação |
|---|---|
| Nome | Colossal Foods |
| Natureza | Empresa privada, com fins lucrativos, do segmento de alimentação (hamburgueria) |
| Endereço | Rua do Carvalho Brasileiro, Jardim Arantes — São Paulo/SP — CEP 08382-520 |
| Telefone da organização | (11) 95950-6213 |
| Referência pública | Perfil no Google Maps: “Colossal Foods — Jardim Arantes, São Paulo — SP” (nota 5,0 com 228 avaliações na consulta feita durante a Entrega 1) — [link do perfil](https://share.google/RllPzCXwKrrXsxuzK) |
| Responsável que atendeu o grupo | Henrique Lemos, responsável pela Colossal Foods — (11) 95950-6213 |
| Cardápio | Digital, fornecido por empresa terceirizada mediante mensalidade **[E]** |

## 2. Visitas e entrevista

| Item | Registro |
|---|---|
| Data | Setembro de 2026 (data exata não registrada) |
| Local | Colossal Foods, Jardim Arantes |
| Entrevistado (nome e função) | Henrique Lemos, responsável |
| Integrantes presentes | Murilo Silva Magalhães |
| Fotos | Fachada: [evidencias/fachada.jpg](evidencias/fachada.jpg) · pasta `levantamento/evidencias/` |

## 3. Porte e volume

| Indicador | Valor | Origem |
|---|---|---|
| Funcionários na chapa/preparo | 2 | [O] |
| Funcionários no atendimento | 2 | [O] |
| Motoboy fixo | 1 | [E] |
| Pedidos por dia em dias de semana | 30 a 50 (estimativa) | [E] |
| Pedidos por dia no fim de semana | 60 a 90 (estimativa) | [E] |
| Taxa de entrega | R$ 2,00 | [E] |
| Formas de pagamento | PIX, dinheiro, cartão de débito, cartão de crédito | [E] |
| Fechamento de caixa | Conferência coletiva ao fim do expediente | [E] |
| Recebimento de insumos | Conferência com a nota fiscal antes de armazenar | [E] |

Com esses números, a operação fica em torno de **300 a 330 pedidos por semana** (5 × 40 + 2 × 75). Esse é o volume usado para dimensionar a massa de dados (seção 4 do README).

## 4. O que foi observado × o que foi dito

**Observado no local [O]:** composição da equipe (2 na chapa, 2 no atendimento); o pedido chega pelo cardápio digital terceirizado e o atendimento consulta e confere as informações manualmente; o grupo não tem acesso ao banco de dados da plataforma terceirizada.

**Informado pela equipe [E]:** volume médio de pedidos; motoboy fixo; formas de pagamento aceitas; conferência do caixa ao final do dia por forma de pagamento; conferência de insumos com nota fiscal; cancelamento só é simples enquanto o pedido não entrou em preparo.

## 5. Problemas identificados

| Código | Problema | Origem | Como o banco resolve |
|---|---|---|---|
| P1 | Falhas no tempo de expedição do delivery: não há registro de quando o pedido ficou pronto, saiu e foi entregue | [E] | HISTORICO_STATUS_PEDIDO e ENTREGA guardam os horários; G01, G12 e G13 medem tempos e atrasos |
| P2 | Falta de controle do preço praticado frente à variação de custo dos ingredientes | [E] | ITEM_PEDIDO guarda o preço praticado; ITEM_COMPRA guarda o custo; G02, G03 e G15 comparam |
| P3 | Estoque de ingredientes sem registro de entradas, saídas e mínimo de reposição | [P] | MOVIMENTACAO_ESTOQUE e INGREDIENTE.estoque_minimo; G04 |
| P4 | Cancelamentos sem registro de motivo e de quem autorizou | [E]/[P] | HISTORICO_STATUS_PEDIDO com motivo e autorizador; G05 |
| P5 | Conferência do caixa feita sem registro do valor esperado por forma de pagamento | [E] | PAGAMENTO, FECHAMENTO_CAIXA e CONFERENCIA_CAIXA; G06 e G10 |
| P6 | Compras e recebimentos sem rastreabilidade de fornecedor, nota e quantidade | [E]/[P] | COMPRA e ITEM_COMPRA; G07 |
| P7 | Áreas atendidas e taxas de entrega sem cadastro | [P] | AREA_ENTREGA e taxa aplicada em ENTREGA; G08 |

## 6. Parâmetros que precisam de confirmação

Os valores abaixo foram usados na massa de dados como **exemplos plausíveis**, não como dados reais:

- bairros atendidos além do Jardim Arantes (a taxa de entrega é de R$ 2,00, informada pela organização, e é a mesma em todas as áreas da massa);
- estoque mínimo de cada ingrediente e as embalagens de compra;
- dias de entrega de cada fornecedor;
- dias e horário de funcionamento (a massa considera todos os dias, das 18h às 23h30);
- se o motoboy leva mais de um pedido por saída (a massa considera até 4);
- metas dos KPIs (seção 1.6 do README).

## 7. Mudanças em relação à Entrega 1

1. Os problemas foram numerados (P1–P7) e ligados a tabelas e consultas.
2. Entraram no modelo os processos de compra/recebimento, movimentação de estoque, fechamento de caixa, histórico de status e áreas de entrega, que existiam na rotina mas não estavam no DER.
3. Os requisitos foram reescritos com os dados envolvidos em cada um.
4. Foram acrescentadas as regras RN21 a RN25.
