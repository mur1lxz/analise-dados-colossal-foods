"""Gera o DER conceitual revisado e o modelo lógico da Colossal Foods em Graphviz (DOT),
seguindo a notação do brModelo exigida no roteiro da Entrega 2.

Uso: python3 gerar_diagramas.py   (requer o Graphviz instalado: comando `dot`)
Saídas: der-conceitual.dot/.png/.svg e modelo-logico.dot/.png/.svg nesta pasta.
"""
import pathlib
import re
import subprocess

AQUI = pathlib.Path(__file__).resolve().parent
SCRIPT = AQUI.parent / 'script.sql'

ENT_BG, ENT_HEAD, REL_BG, INK = '#eef4fb', '#cfe0f5', '#fdf3e1', '#1f2933'
FONTE = 'Helvetica'

# ------------------------------------------------------------------ DER conceitual
ENTIDADES = {
    'CLIENTE': ['id_cliente', 'nome', 'telefone'],
    'PEDIDO': ['id_pedido', 'data_hora', 'tipo_pedido', 'status'],
    'PRODUTO': ['id_produto', 'nome', 'descricao', 'preco', 'disponivel'],
    'CATEGORIA': ['id_categoria', 'nome', 'descricao'],
    'INGREDIENTE': ['id_ingrediente', 'nome', 'unidade_medida', 'estoque_minimo'],
    'FORNECEDOR': ['id_fornecedor', 'nome', 'telefone', 'email'],
    'PAGAMENTO': ['id_pagamento', 'forma_pagamento', 'valor', 'data_hora'],
    'ENTREGA': ['id_entrega', 'endereco (logradouro, numero,', '   complemento, cep)', 'taxa_entrega_aplicada',
                'data_hora_saida', 'data_hora_entrega', 'status'],
    'MOTOBOY': ['id_motoboy', 'nome', 'telefone'],
    'AREA_ENTREGA': ['id_area_entrega', 'bairro', 'taxa_padrao', 'ativo'],
    'FUNCIONARIO': ['id_funcionario', 'nome', 'funcao', 'telefone', 'ativo'],
    'HISTORICO_STATUS_PEDIDO': ['id_historico', 'status_anterior', 'status_novo', 'data_hora', 'motivo'],
    'COMPRA': ['id_compra', 'data_pedido', 'data_recebimento', 'numero_nota_fiscal', 'status_compra',
               'resultado_conferencia', 'observacao_conferencia'],
    'MOVIMENTACAO_ESTOQUE': ['id_movimentacao', 'tipo_movimentacao', 'quantidade', 'data_hora', 'motivo'],
    'FECHAMENTO_CAIXA': ['id_fechamento', 'data_hora_inicio', 'data_hora_fim', 'observacao'],
    'CONFERENCIA_CAIXA': ['id_conferencia', 'forma_pagamento', 'valor_contado'],
}
# (relacionamento, entidade A, card. junto de A, entidade B, card. junto de B, atributos do relacionamento)
RELACIONAMENTOS = [
    ('REALIZA', 'CLIENTE', '(1,1)', 'PEDIDO', '(0,n)', []),
    ('CONTÉM', 'PEDIDO', '(0,n)', 'PRODUTO', '(1,n)', ['quantidade', 'preco_unitario', 'observacao']),
    ('CLASSIFICA', 'CATEGORIA', '(1,1)', 'PRODUTO', '(0,n)', []),
    ('COMPÕE', 'PRODUTO', '(0,n)', 'INGREDIENTE', '(0,n)', ['quantidade_utilizada']),
    ('FORNECE', 'FORNECEDOR', '(1,n)', 'INGREDIENTE', '(1,n)', []),
    ('QUITA', 'PEDIDO', '(1,1)', 'PAGAMENTO', '(0,1)', []),
    ('GERA', 'PEDIDO', '(1,1)', 'ENTREGA', '(0,1)', []),
    ('TRANSPORTA', 'MOTOBOY', '(1,1)', 'ENTREGA', '(0,n)', []),
    ('DESTINA', 'AREA_ENTREGA', '(1,1)', 'ENTREGA', '(0,n)', []),
    ('REGISTRA', 'FUNCIONARIO', '(1,1)', 'PEDIDO', '(0,n)', []),
    ('PREPARA', 'FUNCIONARIO', '(0,1)', 'PEDIDO', '(0,n)', []),
    ('TEM', 'PEDIDO', '(1,1)', 'HISTORICO_STATUS_PEDIDO', '(1,n)', []),
    ('ALTERA', 'FUNCIONARIO', '(1,1)', 'HISTORICO_STATUS_PEDIDO', '(0,n)', []),
    ('AUTORIZA', 'FUNCIONARIO', '(0,1)', 'HISTORICO_STATUS_PEDIDO', '(0,n)', []),
    ('ABASTECE', 'FORNECEDOR', '(1,1)', 'COMPRA', '(0,n)', []),
    ('CONFERE', 'FUNCIONARIO', '(0,1)', 'COMPRA', '(0,n)', []),
    ('MOVIMENTA', 'INGREDIENTE', '(1,1)', 'MOVIMENTACAO_ESTOQUE', '(0,n)', []),
    ('LANÇA', 'FUNCIONARIO', '(1,1)', 'MOVIMENTACAO_ESTOQUE', '(0,n)', []),
    ('CONCILIA', 'FECHAMENTO_CAIXA', '(0,1)', 'PAGAMENTO', '(0,n)', []),
    ('FECHA', 'FUNCIONARIO', '(0,1)', 'FECHAMENTO_CAIXA', '(0,n)', []),
    ('DETALHA', 'FECHAMENTO_CAIXA', '(1,1)', 'CONFERENCIA_CAIXA', '(1,n)', []),
]
# entidade associativa: relacionamento ITEM_COMPRA (COMPRA N:N INGREDIENTE) envolvido por um retângulo
ASSOCIATIVA = ('ITEM_COMPRA', 'COMPRA', '(0,n)', 'INGREDIENTE', '(1,n)',
               ['quantidade_solicitada', 'quantidade_recebida', 'custo_unitario'])
LIGACOES_ASSOCIATIVA = [('ORIGINA', 'ITEM_COMPRA', '(0,1)', 'MOVIMENTACAO_ESTOQUE', '(0,n)')]


def ent_label(nome, attrs, tipos=None):
    linhas = [f'<TR><TD BGCOLOR="{ENT_HEAD}" COLSPAN="{3 if tipos else 1}"><B>{nome}</B></TD></TR>']
    for i, a in enumerate(attrs):
        if tipos is None:
            txt = f'<U>{a}</U>' if i == 0 else a
            linhas.append(f'<TR><TD ALIGN="LEFT">{txt}</TD></TR>')
        else:
            tipo, chave = tipos[i]
            linhas.append(f'<TR><TD ALIGN="LEFT">{a}</TD><TD ALIGN="LEFT"><FONT COLOR="#52606d">{tipo}</FONT></TD>'
                          + (f'<TD ALIGN="LEFT"><B>{chave}</B></TD></TR>' if chave else '<TD> </TD></TR>'))
    return (f'<<TABLE BORDER="2" CELLBORDER="0" CELLSPACING="0" CELLPADDING="3" BGCOLOR="{ENT_BG}" COLOR="{INK}">'
            + ''.join(linhas) + '</TABLE>>')


def node_id(nome):
    return re.sub(r'\W', '_', nome)


def der():
    out = ['digraph DER {', '  graph [layout=dot, rankdir=LR, splines=true, nodesep=0.35, ranksep=0.55, '
           f'compound=true, fontname="{FONTE}", labelloc=t, fontsize=22, pad=0.3, '
           'label="DER conceitual revisado — Colossal Foods (notação brModelo; identificador sublinhado; (mín, máx))"];',
           f'  node [fontname="{FONTE}", fontsize=11]; edge [dir=none, color="{INK}", fontname="{FONTE}", '
           'fontsize=10, fontcolor="#2f5d8a", labeldistance=1.6, labelangle=25];']
    for e, attrs in ENTIDADES.items():
        out.append(f'  {node_id(e)} [shape=plaintext, label={ent_label(e, attrs)}];')

    def rel(nome, a, ca, b, cb, attrs):
        rid = 'R_' + node_id(nome)
        out.append(f'  {rid} [shape=diamond, style=filled, fillcolor="{REL_BG}", label="{nome}", '
                   'fontsize=10, width=1.3, height=0.6, fixedsize=true];')
        out.append(f'  {node_id(a)} -> {rid} [taillabel="{ca}"];')
        out.append(f'  {rid} -> {node_id(b)} [headlabel="{cb}"];')
        for at in attrs:
            aid = f'A_{rid}_{node_id(at)}'
            out.append(f'  {aid} [shape=plaintext, label="○ {at}", fontsize=10];')
            out.append(f'  {rid} -> {aid} [color="#7b8794", minlen=1];')
        return rid

    for r in RELACIONAMENTOS:
        rel(*r)
    nome, a, ca, b, cb, attrs = ASSOCIATIVA
    out.append('  subgraph cluster_item_compra { style="bold"; color="#1f2933"; penwidth=2; '
               'label="entidade associativa"; fontsize=9; fontcolor="#52606d"; margin=10;')
    rid = 'R_' + node_id(nome)
    out.append(f'    {rid} [shape=diamond, style=filled, fillcolor="{REL_BG}", label="{nome}", fontsize=10, '
               'width=1.4, height=0.6, fixedsize=true];')
    for at in attrs:
        aid = f'A_{rid}_{node_id(at)}'
        out.append(f'    {aid} [shape=plaintext, label="○ {at}", fontsize=10];')
    out.append('  }')
    for at in attrs:
        out.append(f'  {rid} -> A_{rid}_{node_id(at)} [color="#7b8794", minlen=1];')
    out.append(f'  {node_id(a)} -> {rid} [taillabel="{ca}", lhead=cluster_item_compra];')
    out.append(f'  {rid} -> {node_id(b)} [headlabel="{cb}", ltail=cluster_item_compra];')
    for (rn, x, cx, y, cy) in LIGACOES_ASSOCIATIVA:
        r2 = 'R_' + node_id(rn)
        out.append(f'  {r2} [shape=diamond, style=filled, fillcolor="{REL_BG}", label="{rn}", fontsize=10, '
                   'width=1.3, height=0.6, fixedsize=true];')
        out.append(f'  {rid} -> {r2} [taillabel="{cx}", ltail=cluster_item_compra];')
        out.append(f'  {r2} -> {node_id(y)} [headlabel="{cy}"];')
    out.append('}')
    return '\n'.join(out)


# ------------------------------------------------------------------ modelo lógico (lido do script SQL)
def tabelas_do_script():
    sql = SCRIPT.read_text(encoding='utf-8')
    tabelas = {}
    for m in re.finditer(r'CREATE TABLE IF NOT EXISTS (\w+) \((.*?)\n\) ENGINE', sql, re.S):
        nome, corpo = m.group(1), m.group(2)
        cols, pk, fks = [], [], {}
        for linha in corpo.split('\n'):
            linha = linha.strip().rstrip(',')
            cm = re.match(r'(\w+) ((?:BIGINT|INT|VARCHAR|DECIMAL|DATETIME|TEXT|TINYINT)[^ ]*(?: UNSIGNED)?)', linha)
            if cm and cm.group(1) not in ('CONSTRAINT', 'INDEX'):
                tipo = cm.group(2).replace(' UNSIGNED', '')
                cols.append((cm.group(1), tipo))
            pm = re.search(r'PRIMARY KEY \(([^)]*)\)', linha)
            if pm:
                pk = [c.strip() for c in pm.group(1).split(',')]
        for fm in re.finditer(r'FOREIGN KEY \((\w+)\)\s+REFERENCES (\w+) \((\w+)\)', corpo):
            fks[fm.group(1)] = fm.group(2)
        uniq = [tuple(c.strip() for c in u.split(',')) for u in re.findall(r'UNIQUE \(([^)]*)\)', corpo)]
        nulos = {l.strip().split()[0] for l in corpo.split('\n')
                 if re.search(r'\bNULL\b', l) and 'NOT NULL' not in l and not l.strip().startswith('CONSTRAINT')}
        tabelas[nome] = dict(cols=cols, pk=pk, fks=fks, uniq=uniq, nulos=nulos)
    return tabelas


def logico():
    tabs = tabelas_do_script()
    out = ['digraph LOGICO {', '  graph [layout=dot, rankdir=LR, splines=true, nodesep=0.3, ranksep=0.9, '
           f'fontname="{FONTE}", labelloc=t, fontsize=22, pad=0.3, '
           'label="Modelo lógico relacional — Colossal Foods (MySQL; 20 tabelas; PK, FK e (mín, máx))"];',
           f'  node [fontname="{FONTE}", fontsize=11, shape=plaintext]; edge [dir=none, color="#52606d", '
           f'fontname="{FONTE}", fontsize=10, fontcolor="#2f5d8a", labeldistance=1.7, labelangle=20];']
    for nome, t in tabs.items():
        tipos = []
        for c, tipo in t['cols']:
            marca = []
            if c in t['pk']:
                marca.append('PK')
            if c in t['fks']:
                marca.append('FK')
            tipos.append((tipo, ', '.join(marca)))
        out.append(f'  {nome} [label={ent_label(nome, [c for c, _ in t["cols"]], tipos)}];')
    for nome, t in tabs.items():
        for col, ref in t['fks'].items():
            opcional = col in t['nulos']
            unico = any(u == (col,) for u in t['uniq'])
            ponta_ref = '(0,1)' if opcional else '(1,1)'
            ponta_fk = '(0,1)' if unico else '(0,n)'
            if nome in ('ITEM_PEDIDO',) and ref == 'PEDIDO':
                ponta_fk = '(1,n)'  # RN02: pedido tem ao menos um item
            if nome == 'HISTORICO_STATUS_PEDIDO' and col == 'id_pedido':
                ponta_fk = '(1,n)'  # RN24: todo pedido tem histórico
            if nome == 'CONFERENCIA_CAIXA':
                ponta_fk = '(1,n)'  # RN18: fechamento possui conferência
            if nome == 'ITEM_COMPRA' and ref == 'COMPRA':
                ponta_fk = '(1,n)'
            out.append(f'  {nome} -> {ref} [taillabel="{ponta_fk}", headlabel="{ponta_ref}", '
                       f'tooltip="{nome}.{col} → {ref}"];')
    out.append('}')
    return '\n'.join(out), tabs


def render(nome, dot_src):
    (AQUI / f'{nome}.dot').write_text(dot_src, encoding='utf-8')
    for fmt, extra in (('png', ['-Gdpi=110']), ('svg', [])):
        subprocess.run(['dot', f'-T{fmt}', *extra, str(AQUI / f'{nome}.dot'), '-o', str(AQUI / f'{nome}.{fmt}')],
                       check=True)


if __name__ == '__main__':
    render('der-conceitual', der())
    src, tabs = logico()
    render('modelo-logico', src)
    print(f'{len(tabs)} tabelas; {sum(len(t["fks"]) for t in tabs.values())} chaves estrangeiras')
