# Entrega 1 — Modelo Conceitual (DER)
### Modelagem de um sistema de gestão de informações para uma organização de pequeno porte

---

## Metadados

- **Murilo Silva Magalhães — RGM: 47820471**
- **Kauê de Lima Pereira — RGM: 48477940**
- **Kauê Gregorio dos Santos — RGM: 47908904**

### Estrutura do repositório

| Arquivo | Conteúdo |
|---|---|
| `README.md` | Documentação completa da entrega |
| `dicionario-dados.html` | Dicionário de dados conceitual completo |
| `diagramas/DER-Colossal-Foods.png` | Diagrama Entidade-Relacionamento conceitual |
| `diagramas/fluxograma-Colossal-Foods.png` | Fluxograma do processo de pedido |
| `diagramas/gerar_der.py` e `diagramas/fluxograma.dot` | Arquivos-fonte usados para gerar os diagramas |

---

## 1. Caracterização da Organização

- **Nome e natureza da organização:** **Colossal Foods**, empresa privada com fins lucrativos do segmento de alimentação, classificada publicamente como hamburgueria.

- **Contexto, porte e volume:** hamburgueria de pequeno/médio porte localizada no Jardim Arantes, em São Paulo. Durante a pesquisa de campo, o grupo identificou **4 funcionários diretamente envolvidos na operação interna**: **2 na chapa/preparação dos alimentos** e **2 no atendimento ao público**, além de **motoboy fixo** para as entregas. A operação envolve cardápio digital, recebimento de pedidos, preparação, pagamento, retirada, delivery e abastecimento junto a fornecedores. A hamburgueria atende a uma **média estimada de 30 a 50 pedidos diários nos dias de semana e de 60 a 90 pedidos por dia aos finais de semana**.

- **Problemas e necessidades identificados:** não foi relatada uma crise operacional crítica, mas identificou-se a necessidade concreta de padronizar a estrutura de dados da operação para **erradicar falhas no tempo de expedição dos pedidos de delivery** e **controlar a precificação histórica de itens** frente ao aumento do custo dos ingredientes. O sistema garante a rastreabilidade entre clientes, cardápio, pedidos, entregas e fornecedores, mantendo a separação em relação à plataforma terceirizada de cardápio digital.

- **Justificativa da escolha:** a Colossal Foods foi escolhida por ser uma organização real à qual o grupo tem acesso para pesquisa de campo. Sua operação apresenta processos suficientes para a modelagem conceitual (pedido, produção, pagamento, retirada, delivery e abastecimento) sem complexidade excessiva para esta primeira etapa.

- **Evidências da organização:** o grupo realizou pesquisa de campo diretamente na organização, por meio de entrevista com a equipe. Não foram registradas fotos durante a visita; a existência da organização pode ser verificada pelos dados públicos abaixo, obtidos no perfil da empresa no Google Maps.

| Dado | Informação |
|---|---|
| **Nome** | Colossal Foods |
| **Segmento** | Hamburgueria (alimentação) |
| **Natureza** | Empresa privada com fins lucrativos |
| **Endereço** | Rua do Carvalho Brasileiro, Jardim Arantes — São Paulo/SP |
| **CEP** | 08382-520 |
| **Telefone** | (11) 95950-6213 |
| **Avaliação no Google** | 5,0 (228 avaliações, na consulta feita durante o projeto) |
| **Equipe observada** | 2 funcionários na chapa, 2 no atendimento e 1 motoboy fixo |
| **Cardápio** | Digital, fornecido por empresa terceirizada |
| **Referência pública** | Pesquisar no Google Maps por “Colossal Foods — Jardim Arantes, São Paulo — SP” |

---

## 2. Processos de Negócio

### Principais processos mapeados

- **1. Consulta ao cardápio —** O cliente consulta os produtos disponíveis no cardápio digital terceirizado.
- **2. Realização do pedido —** O cliente escolhe os produtos e envia o pedido.
- **3. Recebimento e atendimento —** A equipe de atendimento recebe, confere e registra o pedido, encaminhando-o para a chapa.
- **4. Preparação —** A equipe da chapa prepara os produtos utilizando os ingredientes disponíveis.
- **5. Pagamento —** O pagamento é registrado e associado ao pedido.
- **6. Retirada —** Quando o pedido é para retirada, o cliente o recebe no estabelecimento.
- **7. Delivery —** Quando o pedido é para entrega, ele é passado ao motoboy fixo, que o leva até o endereço do cliente.
- **8. Finalização —** Após a retirada ou a entrega, o pedido é considerado concluído.
- **9. Abastecimento (processo de apoio) —** Fornecedores entregam os ingredientes usados na preparação.
- **10. Cancelamento e alteração —** O atendimento verifica a viabilidade de cancelar ou alterar pedidos antes que entrem na etapa de preparação.
- **11. Recebimento e conferência de insumos —** A equipe realiza a conferência dos ingredientes entregues pelos fornecedores frente à nota fiscal antes de armazená-los.
- **12. Fechamento de caixa —** Ao final do expediente, a equipe consolida o total arrecadado em dinheiro, PIX e cartões com os pedidos finalizados.

### Fluxograma

![Fluxograma do processo de pedido](diagramas/fluxograma-Colossal-Foods.png)

<details>
<summary>Versão em Mermaid (renderizada pelo GitHub)</summary>

```mermaid
flowchart TD
    INI([Início]) --> A[Cliente consulta o cardápio digital]
    A --> B[Cliente escolhe os produtos e envia o pedido]
    B --> C[Atendimento recebe, confere e registra o pedido]
    C --> D[Chapa prepara os produtos com os ingredientes]
    D --> E[Pedido pronto]
    E --> F[Registro do pagamento]
    F --> G{Tipo do pedido?}
    G -->|Retirada| H[Cliente retira no estabelecimento]
    G -->|Delivery| I[Pedido entregue ao motoboy fixo]
    I --> J[Motoboy entrega no endereço do cliente]
    H --> K[Pedido finalizado]
    J --> K
    K --> FIM([Fim])

    subgraph Abastecimento [Processo de apoio: abastecimento]
        S1[Fornecedores entregam os ingredientes] --> S2[Ingredientes disponíveis na cozinha]
    end
    S2 -.->|insumos| D
