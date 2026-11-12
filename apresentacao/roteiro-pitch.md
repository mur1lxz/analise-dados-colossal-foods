# Apresentação — Colossal Foods
## Slides para apresentação final (roteiro de 8 integrantes)

### Slide 1 — Capa
**Colossal Foods — Sistema de Gestão de Informações**
Modelagem de dados, implementação SQL e consultas gerenciais.
Curso: Análise e Desenvolvimento de Sistemas.

### Slide 2 — Organização e contexto
- Hamburgueria de pequeno porte.
- Operação com pedidos, pagamentos, delivery, compras e ingredientes.
- Cardápio digital terceirizado, conferido manualmente.
- A proposta organiza informações operacionais em um banco relacional.

### Slide 3 — Problema e objetivo
- Centralizar registros essenciais da operação.
- Preservar histórico de pedidos, preços e pagamentos.
- Acompanhar compras, estoque por movimentações e entregas.
- Apoiar conferência diária do caixa.

### Slide 4 — Modelo conceitual (Entrega 1)
- Entidades principais: Cliente, Pedido, Produto, Ingrediente, Fornecedor, Pagamento, Entrega e Motoboy.
- Relacionamentos representam venda, composição de produtos, fornecimento e delivery.
- O modelo foi revisado após a correção da primeira entrega.

### Slide 5 — Modelo lógico (Entrega 2)
- Modelo relacional implementado com 20 tabelas.
- Chaves primárias e estrangeiras preservam os vínculos.
- Tabelas associativas resolvem relacionamentos N:N.
- Diagrama lógico e dicionário documentam a estrutura.

### Slide 6 — Implementação SQL
- Banco: `colossal_foods`.
- 20 tabelas e 11 triggers.
- Massa fictícia para demonstração.
- Integridade referencial, consultas e registros de auditoria.

### Slide 7 — Consultas gerenciais
- G01: tempos de preparo e entrega.
- G02–G03: histórico de preços e custos.
- G04: ingredientes abaixo do estoque mínimo.
- G05: cancelamentos.
- G06: conciliação de caixa.
- G07–G08: compras, fornecedores, entregas e taxas por área.

### Slide 8 — Auditoria e validação
- A01–A12 verificam regras e inconsistências.
- Após ajuste do valor contado do fechamento para R$ 453,00, as 12 consultas retornaram zero registros na massa demonstrativa.
- As 11 triggers tiveram sua existência conferida; testes funcionais individuais não são afirmados.
- O conjunto de dados é inteiramente fictício.

### Slide 9 — Limitações e próximos passos
- Confirmar em campo taxas, bairros e estoques mínimos ilustrativos.
- Testar individualmente os comportamentos das triggers.
- Evoluir controles conforme as necessidades reais da hamburgueria.
- O sistema não deve ser apresentado como integrado ao cardápio terceirizado.

### Slide 10 — Conclusão
- O projeto transforma requisitos em modelo relacional e banco SQL.
- As consultas apoiam acompanhamento e conferência.
- A documentação permite compreender, executar e evoluir a solução.

### Divisão sugerida entre 8 integrantes
1. Integrante 1: slides 1–2 — apresentação da empresa e contexto.
2. Integrante 2: slide 3 — problema e objetivos.
3. Integrante 3: slide 4 — modelo conceitual.
4. Integrante 4: slide 5 — modelo lógico e relacionamentos.
5. Integrante 5: slide 6 — estrutura do banco e implementação.
6. Integrante 6: slide 7 — consultas gerenciais.
7. Integrante 7: slide 8 — auditorias e validação.
8. Integrante 8: slides 9–10 — limitações e conclusão.

> Ajustem a divisão conforme os integrantes reais. Não afirmem que dados fictícios são dados reais da empresa nem que as triggers foram testadas funcionalmente sem executar cenários próprios.
