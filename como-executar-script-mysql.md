# Como executar o script SQL — Colossal Foods

## Requisitos

- MySQL Server 8.0.16 ou superior.
- MySQL Workbench ou outro cliente que aceite scripts com `DELIMITER`.
- Acesso ao MySQL com permissão para criar banco de dados, tabelas e triggers.

## Execução no MySQL Workbench

1. Abra o MySQL Workbench e conecte-se ao seu servidor local.
2. Abra `docs/script.sql` em uma nova aba SQL.
3. Confira se o servidor é MySQL 8.0.16 ou superior.
4. Execute o arquivo inteiro pelo botão de execução do script (ícone de raio).
5. Ao final, atualize a lista de schemas e selecione `colossal_foods`.
6. Confira as tabelas e execute novamente, individualmente, as consultas `G01` a `G08` e `A01` a `A12` para observar os resultados.

O script cria o schema `colossal_foods`, as 20 tabelas, 11 triggers, insere dados fictícios e executa exemplos de `SELECT`, `JOIN`, `UPDATE`, `DELETE`, consultas gerenciais e consultas de auditoria.

## Executar novamente do zero

O script foi preparado para uma carga inicial. Para repetir a demonstração do zero, execute antes, em uma aba separada:

```sql
DROP DATABASE IF EXISTS colossal_foods;
```

**Atenção:** esse comando apaga integralmente o banco `colossal_foods` e todos os dados existentes nele. Não execute em um banco que contenha dados que queira preservar.

Depois, abra e execute novamente todo o arquivo `docs/script.sql`.

## O que deve aparecer na demonstração

- `G04` deve listar ingredientes fictícios abaixo do estoque mínimo.
- `G05` deve mostrar os pedidos cancelados por dia.
- `G06` deve mostrar a comparação do caixa por forma de pagamento; a massa contém uma divergência fictícia intencional de R$ 2,00 para demonstrar a análise.
- `G07` deve mostrar compras por fornecedor e ingrediente.
- `G08` deve mostrar entregas e taxas por área.
- As auditorias `A01` a `A07` e `A09` a `A12` devem retornar vazias com a massa íntegra. `A08` deve apontar a divergência fictícia do fechamento.

## Observações importantes

- Todos os registros da massa são fictícios; não representam clientes, funcionários, fornecedores ou transações reais.
- Os bairros de exemplo, as taxas e os estoques mínimos precisam ser confirmados em campo antes de serem apresentados como dados reais.
- O script foi revisado por verificações estáticas de estrutura e consistência da massa de dados, mas não foi executado em um servidor MySQL neste ambiente. A execução no MySQL Workbench é necessária para confirmar o comportamento no servidor da faculdade ou na instalação local.