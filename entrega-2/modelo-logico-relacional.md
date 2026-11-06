# Colossal Foods — Modelo Lógico Relacional Revisado

**Versão:** 1.1 — 04/11/2026  
**SGBD de destino:** MySQL 8.0.16 ou superior (InnoDB; necessário para CHECK efetivo)  
**Codificação sugerida:** `utf8mb4`  
**Notação de nomes:** `snake_case`, nomes de tabelas em maiúsculas no diagrama e nomes de colunas em minúsculas no script SQL.

> **Situação do documento:** especificação lógica revisada e alinhada ao arquivo `docs/script.sql`. Ela orienta a montagem do diagrama no brModelo, mas não substitui o diagrama gráfico exigido pelo professor. As tabelas novas ampliam o modelo original para cobrir os processos apontados na correção. Os pontos marcados como “validar” e os valores ilustrativos da massa de dados precisam ser confirmados com a organização antes de serem apresentados como fatos observados.

## 1. Convenções

- **PK**: chave primária.
- **FK**: chave estrangeira.
- **PK, FK**: coluna que participa da chave primária e também referencia outra tabela.
- `BIGINT UNSIGNED`: identificadores inteiros positivos, com `AUTO_INCREMENT` na PK simples.
- `DECIMAL(10,2)`: valores monetários; não usar `FLOAT` para dinheiro.
- `DECIMAL(12,3)`: quantidades de ingredientes, permitindo unidades fracionadas.
- `DATETIME`: data e hora local no MySQL. MySQL não possui o tipo `TIMESTAMP WITH TIME ZONE`.
- `TINYINT(1)`: indicador lógico (0 = não; 1 = sim).
- Valores controlados serão implementados no SQL com `CHECK` (MySQL 8.0.16 ou superior) ou tabela de domínio, conforme decisão final.
- FKs devem receber índices. As PKs já criam índices; índices adicionais serão definidos no script conforme as consultas.

## 2. Tabelas e colunas

### 2.1 Entidades preservadas da Entrega 1

#### CLIENTE
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_cliente` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do cliente. |
| `nome` | VARCHAR(120) | NOT NULL | Nome do cliente. |
| `telefone` | VARCHAR(20) | NULL | Contato para atendimento/entrega; dado pessoal de acesso restrito. |

#### PEDIDO
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_pedido` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do pedido. |
| `id_cliente` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `CLIENTE.id_cliente`. |
| `id_funcionario_registro` | BIGINT UNSIGNED | FK, NOT NULL | Funcionário que registrou/recebeu o pedido. |
| `id_funcionario_preparo` | BIGINT UNSIGNED | FK, NULL | Funcionário responsável pelo preparo, quando identificado. |
| `data_hora` | DATETIME | NOT NULL | Momento do registro. |
| `tipo_pedido` | VARCHAR(10) | NOT NULL, CHECK | Valores: `RETIRADA` ou `DELIVERY`. |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'RECEBIDO', CHECK | Valores propostos: `RECEBIDO`, `EM_PREPARACAO`, `PRONTO`, `FINALIZADO`, `CANCELADO`. `CANCELADO` foi acrescentado para representar o processo de cancelamento. |

**Nota:** `valor_total` continua sendo atributo derivado e não será armazenado em `PEDIDO`. A fórmula adotada na implementação é `SUM(quantidade * preco_unitario)` em `ITEM_PEDIDO` **mais** `ENTREGA.taxa_entrega_aplicada`, quando existir entrega. A inclusão da taxa evita divergência entre o valor cobrado no delivery e o valor pago, conforme RN08 e RN19.

#### PRODUTO
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_produto` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do produto. |
| `id_categoria` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `CATEGORIA.id_categoria`. |
| `nome` | VARCHAR(120) | NOT NULL | Nome no cardápio. |
| `descricao` | TEXT | NULL | Descrição opcional. |
| `preco` | DECIMAL(10,2) | NOT NULL, CHECK (`preco` > 0) | Preço atual de venda. |
| `disponivel` | TINYINT(1) | NOT NULL, DEFAULT 1 | 1 = disponível; 0 = indisponível. |

#### CATEGORIA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_categoria` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da categoria. |
| `nome` | VARCHAR(80) | NOT NULL, UNIQUE | Nome da categoria. |
| `descricao` | VARCHAR(255) | NULL | Descrição opcional. |

#### INGREDIENTE
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_ingrediente` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do ingrediente. |
| `nome` | VARCHAR(120) | NOT NULL | Nome do insumo. |
| `unidade_medida` | VARCHAR(20) | NOT NULL | Ex.: `g`, `kg`, `ml`, `L`, `un`. |
| `estoque_minimo` | DECIMAL(12,3) | NULL, CHECK (`estoque_minimo` >= 0) | Limite para alerta de reposição. **Validar** se a hamburgueria define mínimo por ingrediente. NULL significa que o mínimo ainda não foi definido. |

**Nota:** o saldo atual não será armazenado nesta tabela. Será calculado pelas movimentações de estoque registradas.

#### FORNECEDOR
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_fornecedor` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do fornecedor. |
| `nome` | VARCHAR(150) | NOT NULL | Nome ou razão social. |
| `telefone` | VARCHAR(20) | NULL | Telefone de contato. |
| `email` | VARCHAR(150) | NULL | E-mail de contato. |

#### PAGAMENTO
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_pagamento` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do pagamento. |
| `id_pedido` | BIGINT UNSIGNED | FK, NOT NULL, UNIQUE | Referencia `PEDIDO.id_pedido`; UNIQUE mantém no máximo um pagamento por pedido. |
| `id_fechamento` | BIGINT UNSIGNED | FK, NULL | Referencia `FECHAMENTO_CAIXA.id_fechamento`; NULL enquanto não conciliado. |
| `forma_pagamento` | VARCHAR(20) | NOT NULL, CHECK | `PIX`, `DINHEIRO`, `CARTAO_DEBITO` ou `CARTAO_CREDITO`. |
| `valor` | DECIMAL(10,2) | NOT NULL, CHECK (`valor` > 0) | Valor recebido. Deve corresponder à soma dos itens do pedido mais a taxa de entrega aplicada, quando houver delivery. |
| `data_hora` | DATETIME | NOT NULL | Momento do pagamento. |

#### ENTREGA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_entrega` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da entrega. |
| `id_pedido` | BIGINT UNSIGNED | FK, NOT NULL, UNIQUE | Referencia `PEDIDO.id_pedido`; UNIQUE limita a uma entrega por pedido. |
| `id_motoboy` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `MOTOBOY.id_motoboy`. |
| `id_area_entrega` | BIGINT UNSIGNED | FK, NOT NULL | Referencia a área/bairro atendido. |
| `logradouro` | VARCHAR(150) | NOT NULL | Logradouro de destino. |
| `numero` | VARCHAR(20) | NOT NULL | Número do endereço. |
| `complemento` | VARCHAR(100) | NULL | Complemento opcional. |
| `cep` | VARCHAR(9) | NULL | CEP de destino, quando informado. |
| `taxa_entrega_aplicada` | DECIMAL(10,2) | NOT NULL, DEFAULT 0, CHECK (`taxa_entrega_aplicada` >= 0) | Cópia do valor cobrado no momento da entrega, preservando o histórico. |
| `data_hora_saida` | DATETIME | NULL | Momento da saída do motoboy. |
| `data_hora_entrega` | DATETIME | NULL | Momento da conclusão. Deve ser posterior à saída. |
| `status` | VARCHAR(20) | NOT NULL, DEFAULT 'AGUARDANDO', CHECK | `AGUARDANDO`, `EM_ROTA` ou `ENTREGUE`. |

O bairro é obtido por `AREA_ENTREGA`; a taxa efetivamente cobrada fica registrada em `taxa_entrega_aplicada`, mesmo que a taxa padrão seja alterada no futuro.

#### MOTOBOY
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_motoboy` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do motoboy. |
| `nome` | VARCHAR(120) | NOT NULL | Nome do entregador. |
| `telefone` | VARCHAR(20) | NOT NULL | Telefone para contato operacional. |

### 2.2 Tabelas associativas dos relacionamentos N:N originais

#### ITEM_PEDIDO — relacionamento CONTÉM
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_item_pedido` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da linha do pedido. |
| `id_pedido` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `PEDIDO.id_pedido`. |
| `id_produto` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `PRODUTO.id_produto`. |
| `quantidade` | INT UNSIGNED | NOT NULL, CHECK (`quantidade` > 0) | Quantidade comprada. |
| `preco_unitario` | DECIMAL(10,2) | NOT NULL, CHECK (`preco_unitario` > 0) | Preço praticado no momento da venda, preservado historicamente. |
| `observacao` | VARCHAR(255) | NULL | Ex.: sem cebola, sem molho. |

O identificador próprio permite registrar o mesmo produto mais de uma vez no mesmo pedido quando houver observações/customizações diferentes.

#### PRODUTO_INGREDIENTE — relacionamento COMPÕE
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_produto` | BIGINT UNSIGNED | PK, FK, NOT NULL | Referencia `PRODUTO.id_produto`. |
| `id_ingrediente` | BIGINT UNSIGNED | PK, FK, NOT NULL | Referencia `INGREDIENTE.id_ingrediente`. |
| `quantidade_utilizada` | DECIMAL(12,3) | NOT NULL, CHECK (`quantidade_utilizada` > 0) | Quantidade do ingrediente usada em uma unidade do produto. |

PK composta: (`id_produto`, `id_ingrediente`).

#### FORNECEDOR_INGREDIENTE — relacionamento FORNECE
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_fornecedor` | BIGINT UNSIGNED | PK, FK, NOT NULL | Referencia `FORNECEDOR.id_fornecedor`. |
| `id_ingrediente` | BIGINT UNSIGNED | PK, FK, NOT NULL | Referencia `INGREDIENTE.id_ingrediente`. |

PK composta: (`id_fornecedor`, `id_ingrediente`). Esta tabela representa quais ingredientes cada fornecedor pode fornecer; `COMPRA` e `ITEM_COMPRA` registram as compras efetivamente realizadas.

### 2.3 Novas tabelas para cobrir os processos apontados na correção

#### FUNCIONARIO
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_funcionario` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do funcionário. |
| `nome` | VARCHAR(120) | NOT NULL | Nome do funcionário. |
| `funcao` | VARCHAR(30) | NOT NULL | Ex.: `ATENDIMENTO` ou `CHAPA`. |
| `telefone` | VARCHAR(20) | NULL | Contato, se necessário. |
| `ativo` | TINYINT(1) | NOT NULL, DEFAULT 1 | 1 = ativo; 0 = inativo. |

A tabela permite identificar quem registrou o pedido, quem ficou responsável pelo preparo e quem lançou movimentações. Não foi criada tabela de escala, pois a escala individual não foi confirmada.

#### COMPRA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_compra` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da compra. |
| `id_fornecedor` | BIGINT UNSIGNED | FK, NOT NULL | Fornecedor da compra. |
| `id_funcionario_conferente` | BIGINT UNSIGNED | FK, NULL | Funcionário que conferiu o recebimento; preencher quando recebido. |
| `data_pedido` | DATETIME | NOT NULL | Data/hora da solicitação/compra. |
| `data_recebimento` | DATETIME | NULL | Data/hora em que a mercadoria chegou. |
| `numero_nota_fiscal` | VARCHAR(50) | NULL | Número da nota; torna-se obrigatório quando a compra for recebida, conforme RN20. |
| `status_compra` | VARCHAR(20) | NOT NULL, DEFAULT 'PENDENTE', CHECK | `PENDENTE`, `RECEBIDA` ou `CANCELADA`. |
| `resultado_conferencia` | VARCHAR(20) | NOT NULL, DEFAULT 'PENDENTE', CHECK | `PENDENTE`, `CONFORME` ou `DIVERGENTE`. |
| `observacao_conferencia` | TEXT | NULL | Divergências ou observações do recebimento. |

#### ITEM_COMPRA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_item_compra` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da linha da compra. |
| `id_compra` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `COMPRA.id_compra`. |
| `id_ingrediente` | BIGINT UNSIGNED | FK, NOT NULL | Referencia `INGREDIENTE.id_ingrediente`. |
| `quantidade_solicitada` | DECIMAL(12,3) | NOT NULL, CHECK (> 0) | Quantidade solicitada. |
| `quantidade_recebida` | DECIMAL(12,3) | NOT NULL, DEFAULT 0, CHECK (>= 0) | Quantidade efetivamente recebida. |
| `custo_unitario` | DECIMAL(10,2) | NOT NULL, CHECK (>= 0) | Custo unitário de aquisição. |

Restrição UNIQUE: (`id_compra`, `id_ingrediente`) para evitar duas linhas do mesmo ingrediente na mesma compra. O custo fica preservado para análises históricas.

#### MOVIMENTACAO_ESTOQUE
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_movimentacao` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da movimentação. |
| `id_ingrediente` | BIGINT UNSIGNED | FK, NOT NULL | Ingrediente movimentado. |
| `id_funcionario` | BIGINT UNSIGNED | FK, NOT NULL | Responsável pelo lançamento. |
| `id_item_compra` | BIGINT UNSIGNED | FK, NULL | Referência à linha de compra quando a entrada decorrer de recebimento. |
| `tipo_movimentacao` | VARCHAR(20) | NOT NULL, CHECK | `ENTRADA`, `SAIDA`, `AJUSTE_ENTRADA` ou `AJUSTE_SAIDA`. |
| `quantidade` | DECIMAL(12,3) | NOT NULL, CHECK (> 0) | Quantidade positiva; o tipo define o sentido. |
| `data_hora` | DATETIME | NOT NULL | Momento do lançamento. |
| `motivo` | VARCHAR(255) | NOT NULL | Motivo do lançamento ou ajuste. |

**Decisão de escopo:** as movimentações representam lançamentos/conferências manuais. Não haverá baixa automática de ingredientes a cada venda, pois a informação levantada descreve conferência manual em sistema terceirizado e não confirmou integração automática com pedidos.

#### FECHAMENTO_CAIXA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_fechamento` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do fechamento. |
| `id_funcionario_responsavel` | BIGINT UNSIGNED | FK, NULL | Funcionário que registrou o fechamento no banco; não significa que contou sozinho. **Validar** quem será indicado. |
| `data_hora_inicio` | DATETIME | NULL | Início do período conciliado, se controlado. |
| `data_hora_fim` | DATETIME | NOT NULL | Momento do fechamento. |
| `observacao` | TEXT | NULL | Observações sobre a conferência. |

#### CONFERENCIA_CAIXA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_conferencia` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da conferência. |
| `id_fechamento` | BIGINT UNSIGNED | FK, NOT NULL | Fechamento ao qual pertence. |
| `forma_pagamento` | VARCHAR(20) | NOT NULL, CHECK | `PIX`, `DINHEIRO`, `CARTAO_DEBITO` ou `CARTAO_CREDITO`. |
| `valor_contado` | DECIMAL(10,2) | NOT NULL, CHECK (>= 0) | Valor apurado na conferência física/operacional. |

Restrição UNIQUE: (`id_fechamento`, `forma_pagamento`). O valor esperado por forma de pagamento será calculado somando os registros de `PAGAMENTO` associados ao fechamento; não será duplicado nesta tabela. O fechamento pode estar em preenchimento (`0..4` conferências); um fechamento concluído deve ter ao menos uma conferência para cada forma de pagamento utilizada. A consulta A11 verifica fechamento sem conferência.

#### HISTORICO_STATUS_PEDIDO
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_historico` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador do evento. |
| `id_pedido` | BIGINT UNSIGNED | FK, NOT NULL | Pedido cujo status mudou. |
| `id_funcionario_responsavel` | BIGINT UNSIGNED | FK, NOT NULL | Funcionário que registrou a alteração. |
| `id_funcionario_autorizador` | BIGINT UNSIGNED | FK, NULL | Funcionário que autorizou cancelamento fora do status inicial, se aplicável. |
| `status_anterior` | VARCHAR(20) | NULL | Status anterior; NULL no primeiro registro. |
| `status_novo` | VARCHAR(20) | NOT NULL, CHECK | `RECEBIDO`, `EM_PREPARACAO`, `PRONTO`, `FINALIZADO` ou `CANCELADO`. |
| `data_hora` | DATETIME | NOT NULL | Momento da mudança. |
| `motivo` | VARCHAR(255) | NULL | Justificativa; obrigatória para cancelamento conforme regra a implementar. |

#### AREA_ENTREGA
| Coluna | Tipo MySQL | Chave / restrição | Observação |
|---|---|---|---|
| `id_area_entrega` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Identificador da área atendida. |
| `bairro` | VARCHAR(100) | NOT NULL, UNIQUE | Bairro/área atendida. |
| `taxa_padrao` | DECIMAL(10,2) | NOT NULL, DEFAULT 0, CHECK (>= 0) | Taxa padrão configurada. |
| `ativo` | TINYINT(1) | NOT NULL, DEFAULT 1 | 1 = atendido; 0 = fora de atendimento. |

**Validar em campo:** bairros efetivamente atendidos e valor da taxa fixa. A existência da regra de área/taxa foi apontada na correção, mas os bairros e valores exatos ainda precisam ser confirmados.

## 3. Relacionamentos e cardinalidades

A cardinalidade abaixo é descrita em linguagem direta para evitar ambiguidade: primeiro aparece o número de ocorrências do lado “pai” para cada ocorrência do lado “filho”. No desenho do brModelo, indicar os pares `(mín,máx)` nas duas pontas.

| Relacionamento | Cardinalidade | Implementação relacional |
|---|---|---|
| CLIENTE realiza PEDIDO | Um cliente realiza `0..N` pedidos; cada pedido pertence a `1..1` cliente. | FK `PEDIDO.id_cliente`. |
| PEDIDO contém PRODUTO | Um pedido pode conter `0..N` linhas segundo as restrições físicas; um produto aparece em `0..N` linhas de pedido. O fluxo de pagamento exige ao menos um item, mas a FK isolada não impõe essa participação mínima. | Associativa `ITEM_PEDIDO`. |
| CATEGORIA classifica PRODUTO | Uma categoria classifica `0..N` produtos; cada produto pertence a `1..1` categoria. | FK `PRODUTO.id_categoria`. |
| PRODUTO compõe INGREDIENTE | Um produto tem `0..N` ingredientes; um ingrediente compõe `0..N` produtos. | Associativa `PRODUTO_INGREDIENTE`. |
| FORNECEDOR fornece INGREDIENTE | Um fornecedor pode estar associado a `0..N` ingredientes e um ingrediente a `0..N` fornecedores no modelo físico; a tabela associativa não impõe mínimo de uma associação. | Associativa `FORNECEDOR_INGREDIENTE`. |
| PEDIDO possui PAGAMENTO | Um pedido possui `0..1` pagamento; cada pagamento pertence a `1..1` pedido. | FK `PAGAMENTO.id_pedido` com UNIQUE. |
| PEDIDO gera ENTREGA | Um pedido gera `0..1` entrega; cada entrega pertence a `1..1` pedido. | FK `ENTREGA.id_pedido` com UNIQUE. |
| MOTOBOY transporta ENTREGA | Um motoboy realiza `0..N` entregas; cada entrega tem `1..1` motoboy. | FK `ENTREGA.id_motoboy`. |
| FUNCIONARIO registra PEDIDO | Um funcionário registra `0..N` pedidos; cada pedido tem `1..1` funcionário registrador. | FK `PEDIDO.id_funcionario_registro`. |
| FUNCIONARIO prepara PEDIDO | Um funcionário prepara `0..N` pedidos; cada pedido possui `0..1` funcionário de preparo identificado. | FK `PEDIDO.id_funcionario_preparo`, nullable. |
| FORNECEDOR realiza COMPRA | Um fornecedor aparece em `0..N` compras; cada compra pertence a `1..1` fornecedor. | FK `COMPRA.id_fornecedor`. |
| COMPRA possui ITEM_COMPRA | Uma compra pode possuir `0..N` itens segundo as FKs; cada item pertence a `1..1` compra. A regra de recebimento exige itens recebidos quando a compra passa a RECEBIDA. | FK `ITEM_COMPRA.id_compra`. |
| INGREDIENTE aparece em ITEM_COMPRA | Um ingrediente aparece em `0..N` itens de compra; cada item aponta para `1..1` ingrediente. | FK `ITEM_COMPRA.id_ingrediente`. |
| INGREDIENTE possui MOVIMENTACAO_ESTOQUE | Um ingrediente possui `0..N` movimentações; cada movimentação se refere a `1..1` ingrediente. | FK `MOVIMENTACAO_ESTOQUE.id_ingrediente`. |
| FUNCIONARIO registra MOVIMENTACAO_ESTOQUE | Um funcionário registra `0..N` movimentações; cada movimentação tem `1..1` responsável. | FK `MOVIMENTACAO_ESTOQUE.id_funcionario`. |
| ITEM_COMPRA origina MOVIMENTACAO_ESTOQUE | Um item de compra origina `0..N` movimentações; uma movimentação está ligada a `0..1` item de compra. | FK nullable `MOVIMENTACAO_ESTOQUE.id_item_compra`. |
| FECHAMENTO_CAIXA possui CONFERENCIA_CAIXA | Um fechamento em preenchimento pode possuir `0..4` conferências; cada conferência pertence a `1..1` fechamento. Um fechamento concluído deve ter ao menos uma conferência para cada forma utilizada. | FK `CONFERENCIA_CAIXA.id_fechamento`, UNIQUE (`id_fechamento`, `forma_pagamento`) e auditoria A11 para fechamento sem conferência. |
| FECHAMENTO_CAIXA reúne PAGAMENTO | Um fechamento reúne `0..N` pagamentos; cada pagamento pertence a `0..1` fechamento. | FK nullable `PAGAMENTO.id_fechamento`. |
| PEDIDO possui HISTORICO_STATUS_PEDIDO | Um pedido pode possuir `0..N` eventos no modelo físico; cada evento pertence a `1..1` pedido. | FK `HISTORICO_STATUS_PEDIDO.id_pedido`. |
| FUNCIONARIO registra HISTORICO_STATUS_PEDIDO | Um funcionário registra `0..N` eventos; cada evento tem `1..1` responsável pelo registro. | FK `HISTORICO_STATUS_PEDIDO.id_funcionario_responsavel`. |
| AREA_ENTREGA atende ENTREGA | Uma área atende `0..N` entregas; cada entrega está vinculada a `1..1` área. | FK `ENTREGA.id_area_entrega`. |

## 4. Resumo das chaves estrangeiras

| Tabela de origem | FK | Tabela/coluna referenciada |
|---|---|---|
| PEDIDO | `id_cliente` | CLIENTE(`id_cliente`) |
| PEDIDO | `id_funcionario_registro` | FUNCIONARIO(`id_funcionario`) |
| PEDIDO | `id_funcionario_preparo` | FUNCIONARIO(`id_funcionario`) |
| PRODUTO | `id_categoria` | CATEGORIA(`id_categoria`) |
| PAGAMENTO | `id_pedido` | PEDIDO(`id_pedido`) |
| PAGAMENTO | `id_fechamento` | FECHAMENTO_CAIXA(`id_fechamento`) |
| ENTREGA | `id_pedido` | PEDIDO(`id_pedido`) |
| ENTREGA | `id_motoboy` | MOTOBOY(`id_motoboy`) |
| ENTREGA | `id_area_entrega` | AREA_ENTREGA(`id_area_entrega`) |
| ITEM_PEDIDO | `id_pedido` | PEDIDO(`id_pedido`) |
| ITEM_PEDIDO | `id_produto` | PRODUTO(`id_produto`) |
| PRODUTO_INGREDIENTE | `id_produto` | PRODUTO(`id_produto`) |
| PRODUTO_INGREDIENTE | `id_ingrediente` | INGREDIENTE(`id_ingrediente`) |
| FORNECEDOR_INGREDIENTE | `id_fornecedor` | FORNECEDOR(`id_fornecedor`) |
| FORNECEDOR_INGREDIENTE | `id_ingrediente` | INGREDIENTE(`id_ingrediente`) |
| COMPRA | `id_fornecedor` | FORNECEDOR(`id_fornecedor`) |
| COMPRA | `id_funcionario_conferente` | FUNCIONARIO(`id_funcionario`) |
| ITEM_COMPRA | `id_compra` | COMPRA(`id_compra`) |
| ITEM_COMPRA | `id_ingrediente` | INGREDIENTE(`id_ingrediente`) |
| MOVIMENTACAO_ESTOQUE | `id_ingrediente` | INGREDIENTE(`id_ingrediente`) |
| MOVIMENTACAO_ESTOQUE | `id_funcionario` | FUNCIONARIO(`id_funcionario`) |
| MOVIMENTACAO_ESTOQUE | `id_item_compra` | ITEM_COMPRA(`id_item_compra`) |
| CONFERENCIA_CAIXA | `id_fechamento` | FECHAMENTO_CAIXA(`id_fechamento`) |
| HISTORICO_STATUS_PEDIDO | `id_pedido` | PEDIDO(`id_pedido`) |
| HISTORICO_STATUS_PEDIDO | `id_funcionario_responsavel` | FUNCIONARIO(`id_funcionario`) |
| HISTORICO_STATUS_PEDIDO | `id_funcionario_autorizador` | FUNCIONARIO(`id_funcionario`) |
| FECHAMENTO_CAIXA | `id_funcionario_responsavel` | FUNCIONARIO(`id_funcionario`) |

## 5. Restrições de integridade a implementar no SQL

1. **Integridade referencial:** todas as FKs devem impedir registros órfãos. Recomenda-se `ON DELETE RESTRICT` para preservar histórico de pedidos, pagamentos, compras e movimentações.
2. **Unicidade:** `CATEGORIA.nome`, `AREA_ENTREGA.bairro`, `PAGAMENTO.id_pedido` e `ENTREGA.id_pedido`; além das combinações indicadas para linhas e conferências.
3. **Domínios:** `tipo_pedido`, `status`, `forma_pagamento`, `tipo_movimentacao`, `status_compra`, `resultado_conferencia` e `status` da entrega devem aceitar somente os valores documentados.
4. **Valores positivos:** quantidade de itens, preço praticado, custo unitário, quantidade recebida e movimentada devem respeitar os `CHECK` descritos nas tabelas.
5. **Preço histórico:** não recalcular `ITEM_PEDIDO.preco_unitario` a partir do preço atual de `PRODUTO.preco`.
6. **Pagamento:** o trigger `trg_pagamento_bi`/`trg_pagamento_bu` valida que `PAGAMENTO.valor` corresponda à soma dos itens mais a taxa de entrega aplicada, quando houver delivery. Essa comparação envolve várias tabelas e não é coberta por um `CHECK` simples.
7. **Pedido com item:** garantir que todo pedido confirmado tenha pelo menos uma linha em `ITEM_PEDIDO`. A existência de ao menos uma linha não é assegurada por FK simples; validar na rotina de gravação e incluir consulta de auditoria.
8. **Cancelamento:** guardar cada mudança em `HISTORICO_STATUS_PEDIDO`; o trigger `trg_historico_status_bi` exige justificativa. Para cancelamento após `EM_PREPARACAO` ou `PRONTO`, exige também o autorizador, conforme RN17.
9. **Delivery:** os triggers `trg_entrega_bi`/`trg_entrega_bu` impedem entrega para pedido `RETIRADA`; a auditoria A03 verifica retirada com entrega e delivery ativo sem entrega. O trigger `trg_pedido_bu` impede finalizar delivery antes de a entrega estar marcada como `ENTREGUE`.
10. **Fechamento:** comparar o total de `PAGAMENTO` conciliado com `valor_contado` em `CONFERENCIA_CAIXA`, agrupando por forma de pagamento e fechamento.
11. **Estoque:** saldo calculado como entradas e ajustes positivos menos saídas e ajustes negativos. Não gerar baixa automática de ingredientes a partir de `ITEM_PEDIDO` nesta versão.
12. **Recebimento:** os triggers de COMPRA validam os dados mínimos da nota, data e conferente na inserção como `RECEBIDA` ou na transição de status. A auditoria A10 verifica se há ao menos um item efetivamente recebido (RN20/RN21); a conferência operacional deve ser registrada no processo de recebimento.

## 5.1 Alinhamento com o script SQL e decisões revisadas

O arquivo `docs/script.sql` implementa as 20 tabelas deste modelo, na ordem necessária para criar as chaves estrangeiras no MySQL. Além das constraints, o script contém 11 triggers para as regras que dependem de mais de uma tabela:

- Produto indisponível não pode ser incluído em novo item de pedido (RN05).
- Pagamento deve corresponder ao total dos itens mais a taxa de delivery, quando houver (RN08/RN19).
- Entrega só pode ser cadastrada para pedido `DELIVERY`, área ativa e taxa cadastrada; pedido delivery só pode ser finalizado depois de a entrega estar `ENTREGUE` (RN10/RN14/RN19).
- Compra recebida deve ter dados de nota fiscal, data, conferente, itens e quantidades efetivamente recebidas (RN20/RN21).
- Entrada vinculada a item de compra deve referenciar o mesmo ingrediente, usar o tipo `ENTRADA` e não superar a quantidade recebida (RN23).
- Cancelamento exige justificativa; após início do preparo, exige autorizador (RN17).
- Compra muda de `PENDENTE` para `RECEBIDA` somente depois que os itens foram incluídos e conferidos (RN21).

**Atenção à taxa de entrega:** o atributo `valor_total` continua derivado, mas passa a considerar a taxa registrada em `ENTREGA.taxa_entrega_aplicada`. Essa decisão foi necessária porque a RN19 prevê taxa fixa para delivery. O SQL e as consultas A02/G06 usam a mesma fórmula.

**Massa de dados:** o script carrega 138 pedidos em três dias (34 em um dia útil, 39 em outro e 65 no sábado), 276 itens de pedido, 44 entregas, 132 pagamentos, 484 eventos de histórico, cinco compras, 15 itens de compra, 28 movimentações de estoque e 12 conferências de caixa. Os registros, nomes, contatos, notas, endereços, taxas e valores são fictícios. A quantidade por dia foi escolhida para ser compatível com a estimativa de volume atual descrita no README, sem usar dados reais de clientes.

Os valores de estoque mínimo, taxas e bairros de exemplo não devem ser descritos como valores reais da Colossal Foods sem confirmação em campo. Apenas Jardim Arantes está identificado no material do projeto; os outros dois bairros da massa são rótulos demonstrativos. A consulta A08 também identifica formas de pagamento usadas sem conferência correspondente; A09 audita o histórico de status (RN24) e A12 audita o encerramento de deliveries (RN14).

## 6. Como desenhar no brModelo

No brModelo, criar uma tabela para cada uma das 20 estruturas acima e listar cada coluna com seu tipo de dado. Marcar:

- `PK` nas chaves primárias simples;
- `FK` nas chaves estrangeiras;
- `PK, FK` nas duas colunas de `PRODUTO_INGREDIENTE` e `FORNECEDOR_INGREDIENTE`;
- `PK` composta de (`id_produto`, `id_ingrediente`) nas duas tabelas associativas indicadas;
- ligações com cardinalidades `(mín,máx)` nas duas pontas, conforme a seção 3.

Sugestão de organização visual em áreas para evitar cruzamento de linhas:

1. **Vendas:** CLIENTE, PEDIDO, ITEM_PEDIDO, PRODUTO, CATEGORIA, PAGAMENTO, HISTORICO_STATUS_PEDIDO e FUNCIONARIO.
2. **Delivery:** ENTREGA, MOTOBOY e AREA_ENTREGA.
3. **Insumos e compras:** FORNECEDOR, FORNECEDOR_INGREDIENTE, COMPRA, ITEM_COMPRA, INGREDIENTE, PRODUTO_INGREDIENTE e MOVIMENTACAO_ESTOQUE.
4. **Financeiro:** FECHAMENTO_CAIXA e CONFERENCIA_CAIXA (PAGAMENTO também se conecta a esta área).

O modelo lógico deve ser salvo como imagem/arquivo exportado do próprio brModelo, conforme a exigência da atividade. Este Markdown é a especificação para construir o diagrama, não substitui a imagem final do brModelo.

## 7. Pontos para validar antes de congelar o modelo

- Se a hamburgueria define estoque mínimo para cada ingrediente e como registra entradas, saídas e ajustes no sistema terceirizado/conferência manual.
- Como é formalizado o pedido de compra e o recebimento: número da nota, funcionário que confere e tratamento de divergências.
- Quais bairros são atendidos e qual a taxa padrão de cada área.
- Se há um funcionário claramente identificado como registrador do pedido e responsável pelo preparo; os papéis podem ser preenchidos com a função, sem inventar escala individual.
- Quem é indicado como responsável pelo lançamento do fechamento de caixa, já que a contagem foi descrita como feita em conjunto.
- Como a equipe autoriza cancelamentos após o pedido entrar em preparação ou ficar pronto.

## 8. Contagem final

| Grupo | Tabelas |
|---|---:|
| Entidades originais | 9 |
| Associativas originais convertidas | 3 |
| Novas estruturas operacionais | 8 |
| **Total previsto** | **20** |

A contagem considera a estrutura proposta nesta versão. Se a validação de campo mostrar que alguma nova estrutura não corresponde a um processo real, o modelo deve ser ajustado antes da implementação SQL.