"""Gera docs/dicionario-dados.html a partir das definições do docs/script.sql.

Cada coluna traz: descrição, tipo, tamanho, PK, FK (tabela referenciada), obrigatoriedade (NOT NULL),
unicidade (UNIQUE), valores permitidos (CHECK), valor padrão (DEFAULT) e a regra de negócio relacionada.
Gerar a partir do script garante que o dicionário e o banco implementado digam a mesma coisa.
Uso: python3 gerar_dicionario.py
"""
import html
import json
import pathlib
import re

AQUI = pathlib.Path(__file__).resolve().parent
SQL = (AQUI.parent / 'script.sql').read_text(encoding='utf-8')
DESC = json.loads((AQUI / 'descricoes.json').read_text(encoding='utf-8'))

TABELAS = {
    'CLIENTE': ('Pessoa que faz pedidos para retirada ou delivery. Dado pessoal (LGPD).', 'RF01, RN01, RNF06'),
    'CATEGORIA': ('Agrupamento dos produtos no cardápio (hambúrgueres, bebidas etc.).', 'RF03, RN04'),
    'PRODUTO': ('Item vendido no cardápio, com preço atual e disponibilidade.', 'RF02, RN04, RN05'),
    'INGREDIENTE': ('Insumo usado no preparo e controlado no estoque.', 'RF11, RN22'),
    'PRODUTO_INGREDIENTE': ('Composição (ficha técnica) do produto: relacionamento N:N COMPÕE.', 'RF11, RN15'),
    'FORNECEDOR': ('Empresa que fornece ingredientes.', 'RF12, RN16'),
    'FORNECEDOR_INGREDIENTE': ('Quais ingredientes cada fornecedor fornece: relacionamento N:N FORNECE.', 'RF12, RN16'),
    'FUNCIONARIO': ('Pessoa da equipe interna (atendimento ou chapa) que registra as operações.', 'RF14'),
    'MOTOBOY': ('Entregador responsável pelas entregas do delivery.', 'RF09, RN12'),
    'AREA_ENTREGA': ('Bairro/área atendida pelo delivery, com a taxa padrão vigente.', 'RF18, RN19'),
    'PEDIDO': ('Pedido do cliente (retirada ou delivery) e seu status atual. O valor total é derivado '
               '(soma dos itens + taxa de entrega) e não é armazenado.', 'RF04, RF06, RF08, RF10, RF13, RN01, RN09'),
    'ITEM_PEDIDO': ('Produto incluído em um pedido, com quantidade e preço praticado: relacionamento N:N CONTÉM.',
                    'RF05, RN02, RN03, RN05, RN06, RN07'),
    'PAGAMENTO': ('Pagamento único do pedido, ligado ao fechamento de caixa do expediente.', 'RF07, RN08, RN18, RN25'),
    'ENTREGA': ('Entrega de um pedido DELIVERY: endereço, área, motoboy, taxa aplicada e horários.',
                'RF09, RF10, RN10–RN14, RN19'),
    'HISTORICO_STATUS_PEDIDO': ('Cada mudança de status do pedido, com responsável e, no cancelamento, motivo e autorizador.',
                                'RF20, RN17, RN24'),
    'COMPRA': ('Pedido de compra a um fornecedor e o recebimento conferido com nota fiscal.', 'RF15, RF16, RN20, RN21'),
    'ITEM_COMPRA': ('Ingrediente de uma compra: quantidades solicitada/recebida e custo unitário (entidade associativa).',
                    'RF15, RF16, RN21, RN23'),
    'MOVIMENTACAO_ESTOQUE': ('Entrada, saída ou ajuste manual de estoque; o saldo é calculado pelas movimentações.',
                             'RF17, RN22, RN23'),
    'FECHAMENTO_CAIXA': ('Fechamento do caixa ao fim do expediente.', 'RF19, RN18'),
    'CONFERENCIA_CAIXA': ('Valor contado por forma de pagamento em cada fechamento.', 'RF19, RN18'),
}
ORDEM = ['CLIENTE', 'PEDIDO', 'ITEM_PEDIDO', 'PRODUTO', 'CATEGORIA', 'PAGAMENTO', 'ENTREGA', 'AREA_ENTREGA', 'MOTOBOY',
         'HISTORICO_STATUS_PEDIDO', 'FUNCIONARIO', 'INGREDIENTE', 'PRODUTO_INGREDIENTE', 'FORNECEDOR',
         'FORNECEDOR_INGREDIENTE', 'COMPRA', 'ITEM_COMPRA', 'MOVIMENTACAO_ESTOQUE', 'FECHAMENTO_CAIXA',
         'CONFERENCIA_CAIXA']
TRIGGERS = {
    'ITEM_PEDIDO.id_produto': 'Trigger: produto precisa estar disponível (RN05).',
    'PAGAMENTO.valor': 'Trigger: igual a soma dos itens + taxa de entrega (RN08/RN19).',
    'ENTREGA.id_pedido': 'Trigger: só para pedido DELIVERY (RN10).',
    'ENTREGA.id_area_entrega': 'Trigger: área deve estar ativa (RN19).',
    'ENTREGA.taxa_entrega_aplicada': 'Trigger: igual à taxa padrão da área no momento da entrega (RN19).',
    'PEDIDO.status': 'Trigger: DELIVERY só passa a FINALIZADO com entrega ENTREGUE (RN14).',
    'COMPRA.status_compra': 'Trigger: RECEBIDA exige nota, data, conferente, conferência e item recebido (RN20/RN21).',
    'MOVIMENTACAO_ESTOQUE.id_item_compra': 'Trigger: ENTRADA do mesmo ingrediente, sem superar o recebido (RN23).',
    'HISTORICO_STATUS_PEDIDO.motivo': 'Trigger: obrigatório no cancelamento (RN17).',
    'HISTORICO_STATUS_PEDIDO.id_funcionario_autorizador': 'Trigger: obrigatório ao cancelar após o início do preparo (RN17).',
}


def parse():
    out = {}
    for m in re.finditer(r'CREATE TABLE IF NOT EXISTS (\w+) \((.*?)\n\) ENGINE', SQL, re.S):
        nome, corpo = m.group(1), m.group(2)
        linhas = [l.strip().rstrip(',') for l in corpo.split('\n') if l.strip()]
        cols = []
        for l in linhas:
            if l.startswith(('CONSTRAINT', 'INDEX', 'REFERENCES', 'ON ')):
                continue
            cm = re.match(r'(\w+) (BIGINT UNSIGNED|INT UNSIGNED|VARCHAR\(\d+\)|DECIMAL\(\d+,\d+\)|DATETIME|TEXT|TINYINT\(1\))(.*)', l)
            if not cm:
                continue
            col, tipo, resto = cm.groups()
            dm = re.search(r"DEFAULT ('[^']*'|[\d.]+)", resto)
            cols.append(dict(col=col, tipo=tipo, notnull='NOT NULL' in resto,
                             auto='AUTO_INCREMENT' in resto, default=dm.group(1) if dm else ''))
        pk = re.search(r'PRIMARY KEY \(([^)]*)\)', corpo).group(1).replace(' ', '').split(',')
        fks = {f.group(1): (f.group(2), f.group(3)) for f in
               re.finditer(r'FOREIGN KEY \((\w+)\)\s+REFERENCES (\w+) \((\w+)\)', corpo)}
        uniq = [u.replace(' ', '').split(',') for u in re.findall(r'UNIQUE \(([^)]*)\)', corpo)]
        checks = re.findall(r'CONSTRAINT (\w+) CHECK \((.*)\),?$', corpo, re.M)
        out[nome] = dict(cols=cols, pk=pk, fks=fks, uniq=uniq, checks=checks)
    return out


def tipo_tamanho(t):
    m = re.match(r'(\w+)\(([\d,]+)\)', t)
    if m:
        return m.group(1), m.group(2)
    return t, {'BIGINT UNSIGNED': '8 bytes', 'INT UNSIGNED': '4 bytes', 'DATETIME': '—', 'TEXT': 'até 64 KB'}.get(t, '—')


def e(x):
    return html.escape(x)


tabs = parse()
assert set(tabs) == set(ORDEM), set(tabs) ^ set(ORDEM)
secoes, nav = [], []
total_cols = 0
for t in ORDEM:
    d = tabs[t]
    desc, regras = TABELAS[t]
    nav.append(f'<a href="#{t.lower()}">{t}</a>')
    linhas = []
    for c in d['cols']:
        total_cols += 1
        col = c['col']
        tipo, tam = tipo_tamanho(c['tipo'])
        pk = 'PK' + (' (composta)' if len(d['pk']) > 1 else '') if col in d['pk'] else ''
        fk = f"{d['fks'][col][0]}.{d['fks'][col][1]}" if col in d['fks'] else ''
        uniq = []
        for u in d['uniq']:
            if col in u:
                uniq.append('Sim' if len(u) == 1 else 'Sim, junto com ' + ' + '.join(x for x in u if x != col))
        if col in d['pk'] and len(d['pk']) == 1:
            uniq.append('Sim (PK)')
        chk = [f'<code>{e(expr)}</code>' for _, expr in d['checks'] if re.search(rf'\b{col}\b', expr)]
        default = 'AUTO_INCREMENT' if c['auto'] else c['default']
        obs = DESC.get(f'{t}.{col}', '')
        if f'{t}.{col}' in TRIGGERS:
            obs += (' ' if obs else '') + TRIGGERS[f'{t}.{col}']
        linhas.append(
            f'<tr><td><code>{col}</code></td><td>{e(obs)}</td><td>{tipo}</td><td>{tam}</td><td>{pk}</td>'
            f'<td>{fk}</td><td>{"Sim" if c["notnull"] else "Não"}</td><td>{"<br>".join(uniq) or "Não"}</td>'
            f'<td>{"<br>".join(chk) or "—"}</td><td>{e(default) or "—"}</td></tr>')
    secoes.append(
        f'<section id="{t.lower()}"><h2>{t}</h2><p class="desc">{e(desc)}</p>'
        f'<p class="meta"><strong>Chave primária:</strong> {", ".join(d["pk"])} · '
        f'<strong>Requisitos/regras:</strong> {regras}</p>'
        '<div class="scroll"><table><thead><tr><th>Atributo</th><th>Descrição</th><th>Tipo</th><th>Tamanho</th>'
        '<th>PK</th><th>FK (referência)</th><th>Obrigatório<br>(NOT NULL)</th><th>Único<br>(UNIQUE)</th>'
        '<th>Valores permitidos (CHECK)</th><th>Padrão (DEFAULT)</th></tr></thead><tbody>'
        + ''.join(linhas) + '</tbody></table></div></section>')

pagina = f'''<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Dicionário de Dados — Colossal Foods</title>
<style>
:root{{--ink:#1f2933;--muted:#52606d;--line:#cbd2d9;--blue:#2f5d8a;--head:#e8f0fb;--soft:#f5f7fa}}
*{{box-sizing:border-box}} body{{margin:0;color:var(--ink);font:15px/1.55 "Segoe UI",Roboto,Arial,sans-serif;background:#fff}}
header{{background:var(--ink);color:#fff;padding:32px 24px}} header div,main,nav div{{max-width:1240px;margin:auto}}
header h1{{margin:0;font-size:1.8rem}} header p{{margin:6px 0 0;color:#cbd2d9}}
nav{{position:sticky;top:0;background:#fff;border-bottom:1px solid var(--line);z-index:2}}
nav div{{display:flex;flex-wrap:wrap;gap:6px;padding:10px 24px}}
nav a{{font-size:.8rem;color:var(--blue);border:1px solid var(--line);border-radius:4px;padding:2px 8px;text-decoration:none}}
main{{padding:8px 24px 60px}} section{{scroll-margin-top:70px}}
h2{{margin:36px 0 4px;font-size:1.25rem;display:inline-block;background:var(--head);border:2px solid var(--ink);padding:3px 14px}}
.desc{{margin:8px 0 2px}} .meta{{margin:0 0 8px;color:var(--muted);font-size:.9rem}}
.scroll{{overflow-x:auto}} table{{width:100%;border-collapse:collapse;min-width:1100px;font-size:.86rem}}
th,td{{border:1px solid var(--line);padding:6px 8px;text-align:left;vertical-align:top}} th{{background:var(--soft)}}
code{{font-family:Consolas,monospace;font-size:.92em}} .box{{background:var(--soft);border-left:4px solid var(--blue);padding:10px 14px;margin:20px 0}}
</style></head>
<body>
<header><div><h1>Dicionário de Dados — Colossal Foods</h1>
<p>Entrega 2 · Modelo lógico implementado em MySQL 8.0.16+ · {len(ORDEM)} tabelas · {total_cols} atributos</p>
<p>Gerado automaticamente a partir de <code>docs/script.sql</code> por <code>docs/gerador-dicionario/gerar_dicionario.py</code>.</p></div></header>
<nav><div>{''.join(nav)}</div></nav>
<main>
<div class="box"><strong>Convenções.</strong> PK = chave primária; FK = chave estrangeira (tabela.coluna referenciada;
todas com <code>ON UPDATE CASCADE ON DELETE RESTRICT</code>, para não apagar histórico); Obrigatório = <code>NOT NULL</code>;
Único = <code>UNIQUE</code>; Valores permitidos = <code>CHECK</code>; Padrão = <code>DEFAULT</code>.
Valores monetários em <code>DECIMAL(10,2)</code>; quantidades de insumos em <code>DECIMAL(12,3)</code>; datas em
<code>DATETIME</code> (horário local); indicadores lógicos em <code>TINYINT(1)</code> (0 = não, 1 = sim).
Regras que dependem de mais de uma tabela são garantidas por triggers e estão indicadas na descrição do atributo.</div>
<div class="box"><strong>Atributos derivados (não armazenados):</strong> valor total do pedido =
<code>SUM(ITEM_PEDIDO.quantidade × preco_unitario) + ENTREGA.taxa_entrega_aplicada</code> (RF06);
saldo do ingrediente = <code>ENTRADA + AJUSTE_ENTRADA − SAIDA − AJUSTE_SAIDA</code> em MOVIMENTACAO_ESTOQUE (RN22).</div>
{''.join(secoes)}
</main></body></html>
'''
(AQUI.parent / 'dicionario-dados.html').write_text(pagina, encoding='utf-8')
print(f'{len(ORDEM)} tabelas, {total_cols} atributos')
