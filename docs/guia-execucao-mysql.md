# Como executar e validar o script SQL — Colossal Foods

## Requisitos

- MySQL Server 8.0.16 ou superior.
- MySQL Workbench ou outro cliente que aceite scripts com `DELIMITER`.
- Usuário do MySQL com permissão para criar banco de dados, tabelas e triggers.

## Executar no MySQL Workbench

1. Abra o MySQL Workbench e conecte-se ao servidor local.
2. Abra o arquivo `entrega-2/script.sql` em uma nova aba SQL.
3. Confira a versão do servidor com `SELECT VERSION();`.
4. Execute o script completo pelo botão de execução (ícone de raio).
5. Atualize a lista de schemas e confirme que o banco `colossal_foods` foi criado.
6. Abra o schema e confira as 20 tabelas.
7. Execute as consultas gerenciais G01–G08 e as consultas de auditoria A01–A12, conforme a identificação no próprio script.

O script cria o banco, as 20 tabelas, 11 triggers, insere dados fictícios e contém consultas gerenciais e de auditoria.

## Reexecutar do zero

Para recriar a demonstração, execute antes:

```sql
DROP DATABASE IF EXISTS colossal_foods;
```

**Atenção:** esse comando apaga o banco `colossal_foods` e todos os dados que estiverem nele. Não o execute se houver dados que deseja preservar. Depois, execute novamente o arquivo completo `entrega-2/script.sql`.

## Resultados esperados das consultas gerenciais

- **G01:** apresenta indicadores de tempo de preparo e deslocamento dos deliveries concluídos.
- **G02:** compara preços atuais e preços registrados nos itens dos pedidos.
- **G03:** permite analisar custos de aquisição dos ingredientes.
- **G04:** lista ingredientes abaixo do estoque mínimo demonstrativo, quando houver.
- **G05:** apresenta os pedidos cancelados por dia.
- **G06:** compara os pagamentos por forma com os valores informados no fechamento de caixa.
- **G07:** apresenta compras por fornecedor e ingrediente.
- **G08:** apresenta entregas e taxas por área.

A quantidade de linhas retornadas depende da massa de dados e dos parâmetros demonstrativos do script.

## Validação registrada pelo grupo

O grupo executou o script no MySQL Workbench e executou as consultas gerenciais G01–G08. Após corrigir o valor contado no fechamento de caixa para R$ 453,00, as consultas de auditoria A01–A12 foram executadas e retornaram zero registros na massa de demonstração.

Esse resultado indica que as verificações implementadas nessas consultas não encontraram as inconsistências que procuram nos dados atuais. Não significa prova de ausência de qualquer erro possível no sistema. A existência das 11 triggers foi conferida, mas cada trigger ainda precisaria de cenários próprios de teste para comprovar seu comportamento.

## Observações importantes

- Todos os registros da massa são fictícios; não representam clientes, funcionários, fornecedores ou transações reais.
- Bairros de exemplo, taxas de entrega e estoques mínimos são parâmetros ilustrativos e devem ser confirmados em campo antes de serem apresentados como dados reais.
- O controle de estoque desta versão é baseado em movimentações registradas; não se deve afirmar que há baixa automática por venda se isso não foi implementado.
