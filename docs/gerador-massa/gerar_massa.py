"""Gerador da massa de dados fictícia da Colossal Foods (Entrega 2).

Gera a seção 3 do docs/script.sql com INSERTs coerentes com:
- volume informado pela organização (30–50 pedidos/dia na semana, 60–90 no fim de semana);
- regras de negócio implementadas nas triggers (RN02, RN05, RN08/RN19, RN10, RN14,
  RN17, RN20/RN21, RN23) e verificadas nas consultas de auditoria.

Todos os nomes, telefones, endereços, notas fiscais, preços e custos são FICTÍCIOS.
Execução: python3 gerar_massa.py > massa.sql   (semente fixa → resultado reprodutível)
"""
import math
import random
import sys
from collections import defaultdict
from datetime import datetime, timedelta

random.seed(20261108)

INICIO = datetime(2026, 10, 26)  # segunda-feira
DIAS = 14                         # 26/10 a 08/11/2026 (duas semanas completas)

# ---------------------------------------------------------------- cadastros
CATEGORIAS = [
    (1, 'Hambúrgueres', 'Lanches preparados na chapa'),
    (2, 'Acompanhamentos', 'Porções e acompanhamentos'),
    (3, 'Bebidas', 'Bebidas industrializadas'),
    (4, 'Sobremesas', 'Sobremesas individuais'),
    (5, 'Combos', 'Combinações de hambúrguer, acompanhamento e bebida'),
]
# id, categoria, nome, descricao, preco_atual, disponivel, peso_venda
PRODUTOS = [
    (1, 1, 'Colossal Burger', 'Hambúrguer clássico da casa', 29.90, 1, 22),
    (2, 1, 'Bacon Burger', 'Hambúrguer com bacon e cheddar', 34.90, 1, 14),
    (3, 1, 'X-Salada', 'Hambúrguer com salada', 31.90, 1, 10),
    (4, 1, 'Double Burger', 'Hambúrguer duplo', 39.90, 1, 8),
    (5, 2, 'Batata Frita', 'Porção de batatas fritas', 14.90, 1, 14),
    (6, 2, 'Onion Rings', 'Porção de anéis de cebola', 16.90, 1, 6),
    (7, 3, 'Refrigerante Lata', 'Bebida industrializada (lata 350 ml)', 6.00, 1, 14),
    (8, 3, 'Água Mineral', 'Bebida industrializada sem composição cadastrada', 4.00, 1, 5),
    (9, 4, 'Brownie', 'Sobremesa de chocolate', 12.00, 1, 4),
    (10, 4, 'Milk-shake Chocolate', 'Milk-shake de chocolate', 15.00, 1, 5),
    (11, 5, 'Combo Colossal', 'Colossal Burger, batata e refrigerante', 44.90, 1, 12),
    (12, 4, 'Milk-shake Morango', 'Sabor sazonal retirado do cardápio (exemplo fictício)', 15.00, 0, 0),
]
PRINCIPAIS = {1, 2, 3, 4, 11}


def preco_praticado(id_produto, dia):
    """Preço vigente na data do pedido (RN07): Bacon Burger e Batata Frita sofreram reajuste em 02/11."""
    reajuste = datetime(2026, 11, 2)
    if id_produto == 2 and dia < reajuste:
        return 32.90
    if id_produto == 5 and dia < reajuste:
        return 13.90
    return next(p[4] for p in PRODUTOS if p[0] == id_produto)


# id, nome, unidade, estoque_minimo, embalagem, fornecedor_principal
INGREDIENTES = [
    (1, 'Pão brioche', 'un', 60, 30, 1),
    (2, 'Carne bovina moída', 'g', 8000, 1000, 2),
    (3, 'Queijo cheddar', 'g', 1500, 1000, 4),
    (4, 'Alface', 'g', 800, 500, 3),
    (5, 'Tomate', 'g', 1000, 500, 3),
    (6, 'Cebola', 'g', 800, 500, 3),
    (7, 'Bacon', 'g', 1000, 500, 2),
    (8, 'Molho especial', 'ml', 1000, 1000, 4),
    (9, 'Batata congelada', 'g', 6000, 2500, 3),
    (10, 'Óleo vegetal', 'ml', 2000, 900, 4),
    (11, 'Refrigerante lata', 'un', 48, 12, 4),
    (12, 'Chocolate em pó', 'g', 800, 500, 4),
    (13, 'Leite integral', 'ml', 3000, 1000, 4),
]
ING = {i[0]: i for i in INGREDIENTES}
COMPOSICAO = {  # produto -> {ingrediente: quantidade}
    1: {1: 1, 2: 180, 3: 30, 4: 15, 5: 20, 8: 20},
    2: {1: 1, 2: 180, 3: 30, 7: 40, 8: 20},
    3: {1: 1, 2: 160, 4: 20, 5: 30, 6: 10},
    4: {1: 2, 2: 320, 3: 60, 8: 30},
    5: {9: 250, 10: 20},
    6: {6: 100, 10: 20},
    7: {11: 1},
    9: {12: 80},
    10: {12: 30, 13: 250},
    11: {1: 1, 2: 180, 3: 30, 9: 150, 10: 12, 11: 1},
    12: {13: 250},
}
FORNECEDORES = [
    (1, 'Padaria Modelo Ltda.', '(11) 90000-1001', 'contato@padaria-modelo.example'),
    (2, 'Açougue Modelo Ltda.', '(11) 90000-1002', 'compras@acougue-modelo.example'),
    (3, 'Hortifruti Modelo Ltda.', '(11) 90000-1003', 'vendas@hortifruti-modelo.example'),
    (4, 'Distribuidora Modelo Ltda.', '(11) 90000-1004', 'contato@distribuidora-modelo.example'),
]
FORNECEDOR_INGREDIENTE = [(1, 1), (2, 2), (2, 7), (3, 4), (3, 5), (3, 6), (3, 9),
                          (4, 3), (4, 7), (4, 8), (4, 9), (4, 10), (4, 11), (4, 12), (4, 13)]
# dias de entrega por fornecedor (0 = segunda)
ENTREGAS_FORNECEDOR = {1: [0, 2, 4, 5], 2: [0, 3, 5], 3: [0, 3, 5], 4: [1, 4]}
CUSTO_BASE = {1: 1.20, 2: 0.040, 3: 0.052, 4: 0.020, 5: 0.030, 6: 0.018, 7: 0.060,
              8: 0.022, 9: 0.012, 10: 0.009, 11: 3.50, 12: 0.080, 13: 0.0060}

FUNCIONARIOS = [
    (1, 'Funcionario Ficticio 01', 'ATENDIMENTO', '(11) 90000-3001', 1),
    (2, 'Funcionario Ficticio 02', 'ATENDIMENTO', '(11) 90000-3002', 1),
    (3, 'Funcionario Ficticio 03', 'CHAPA', '(11) 90000-3003', 1),
    (4, 'Funcionario Ficticio 04', 'CHAPA', '(11) 90000-3004', 1),
    (5, 'Funcionario Ficticio 05', 'ATENDIMENTO', '(11) 90000-3005', 0),
]
AREAS = [  # id, bairro, taxa, ativo, deslocamento (min, max) em minutos
    (1, 'Jardim Arantes', 5.00, 1, (5, 10)),
    (2, 'Bairro Exemplo 01', 6.00, 1, (8, 14)),
    (3, 'Bairro Exemplo 02', 7.00, 1, (10, 17)),
    (4, 'Bairro Exemplo 03', 9.00, 0, (20, 30)),
]
AREA = {a[0]: a for a in AREAS}

N_CLIENTES = 150
CLIENTES_COM_PEDIDO = 138  # 139..150 cadastrados sem pedido no período
clientes = []
for c in range(1, N_CLIENTES + 1):
    area = 1 if c % 20 < 12 else (2 if c % 20 < 17 else 3)  # 60% / 25% / 15%
    tel = f"(11) 9{c:04d}-{(c * 37) % 10000:04d}" if c % 9 else None
    clientes.append((c, f'Cliente Ficticio {c:03d}', tel, area,
                     f'Rua Ficticia {c:03d}', str(10 + (c * 7) % 490),
                     random.choice([None, None, None, 'Casa 2', 'Apto 12', 'Fundos'])))
peso_cliente = [1 / (i ** 0.75) for i in range(1, CLIENTES_COM_PEDIDO + 1)]

OBS = {1: ['Sem cebola', 'Sem tomate', 'Ponto bem passado', 'Molho à parte'],
       2: ['Bacon extra crocante', 'Sem molho', 'Ponto bem passado'],
       3: ['Sem tomate', 'Sem cebola'], 4: ['Ponto bem passado', 'Sem molho'],
       5: ['Sem sal'], 7: ['Bem gelado'], 11: ['Trocar refrigerante por zero', 'Sem cebola']}
MOTIVOS_RECEBIDO = ['Cliente desistiu do pedido (exemplo fictício)',
                    'Pedido duplicado pelo cliente (exemplo fictício)',
                    'Cliente informou endereço fora da área atendida (exemplo fictício)']
MOTIVOS_PREPARO = ['Cliente desistiu após o início do preparo; insumos descartados (exemplo fictício)',
                   'Pagamento não confirmado após o início do preparo (exemplo fictício)']

# ---------------------------------------------------------------- pedidos
pedidos, itens, historico, entregas, pagamentos = [], [], [], [], []
fechamentos, conferencias = [], []
consumo_dia = defaultdict(lambda: defaultdict(float))
id_pedido = id_item = id_hist = id_entrega = id_pag = 0


def minuto_pedido():
    # pico entre 19h30 e 21h30; abertura às 18h, último pedido às 23h30
    return int(min(330, max(0, random.triangular(0, 330, 140))))


for d in range(DIAS):
    dia = INICIO + timedelta(days=d)
    fim_semana = dia.weekday() >= 5
    n = random.randint(60, 90) if fim_semana else random.randint(30, 50)
    p_delivery = 0.22 if fim_semana else 0.27
    horarios = sorted(dia.replace(hour=18) + timedelta(minutes=minuto_pedido()) for _ in range(n))
    dia_pedidos = []
    for t0 in horarios:
        id_pedido += 1
        cliente = random.choices(clientes[:CLIENTES_COM_PEDIDO], peso_cliente)[0]
        tipo = 'DELIVERY' if random.random() < p_delivery else 'RETIRADA'
        f_reg = random.choice([1, 2])
        f_prep = random.choice([3, 4])
        # itens
        k = random.choices([1, 2, 3, 4], [30, 40, 22, 8])[0]
        escolhidos = []
        if random.random() < 0.92:
            escolhidos.append(random.choices([1, 2, 3, 4, 11], [22, 14, 10, 8, 12])[0])
        candidatos = [p for p in PRODUTOS if p[5] == 1]
        while len(escolhidos) < k:
            p = random.choices(candidatos, [c[6] for c in candidatos])[0][0]
            if p not in escolhidos:
                escolhidos.append(p)
        linhas = []
        for p in escolhidos:
            qtd = 2 if random.random() < (0.25 if p in (7, 8) else 0.12) else 1
            obs = random.choice(OBS[p]) if p in OBS and random.random() < 0.15 else None
            linhas.append((p, qtd, preco_praticado(p, dia), obs))
        dia_pedidos.append(dict(id=id_pedido, cliente=cliente, tipo=tipo, f_reg=f_reg,
                                f_prep=f_prep, t0=t0, linhas=linhas, dia=d))

    # preparo com fila na cozinha (dois funcionários na chapa)
    for i, p in enumerate(dia_pedidos):
        carga = sum(1 for q in dia_pedidos[max(0, i - 12):i] if (p['t0'] - q['t0']).seconds < 1800)
        p['t1'] = p['t0'] + timedelta(minutes=random.randint(1, 5))
        qtd_total = sum(l[1] for l in p['linhas'])
        prep = 9 + 2 * qtd_total + random.randint(0, 5) + max(0, carga - 6)
        p['t2'] = p['t1'] + timedelta(minutes=prep)
        r = random.random()
        p['cancel'] = None
        if r < 0.022:
            p['cancel'] = 'RECEBIDO'
        elif r < 0.036:
            p['cancel'] = random.choice(['EM_PREPARACAO', 'PRONTO'])

    # delivery com um único motoboy fixo, levando até 4 pedidos por saída
    fila = sorted([p for p in dia_pedidos if p['tipo'] == 'DELIVERY' and not p['cancel']],
                  key=lambda x: x['t2'])
    livre = dia.replace(hour=18)
    while fila:
        saida = max(livre, fila[0]['t2'] + timedelta(minutes=2))
        lote = [p for p in fila if p['t2'] + timedelta(minutes=2) <= saida][:4]
        for p in lote:
            fila.remove(p)
        t = saida
        for p in sorted(lote, key=lambda x: x['cliente'][3]):
            a = AREA[p['cliente'][3]]
            t += timedelta(minutes=random.randint(*a[4]))
            p['saida'], p['entrega'] = saida, t
        ultima = AREA[sorted(lote, key=lambda x: x['cliente'][3])[-1]['cliente'][3]]
        livre = t + timedelta(minutes=random.randint(*ultima[4]))

    # registros
    id_fech = d + 1
    ultimo_evento = dia.replace(hour=23)
    for p in dia_pedidos:
        for (prod, qtd, preco, obs) in p['linhas']:
            id_item += 1
            itens.append((id_item, p['id'], prod, qtd, preco, obs))
        ev = [(p['f_reg'], None, None, 'RECEBIDO', p['t0'], None)]
        if p['cancel'] == 'RECEBIDO':
            tc = p['t0'] + timedelta(minutes=random.randint(2, 6))
            ev.append((p['f_reg'], None, 'RECEBIDO', 'CANCELADO', tc, random.choice(MOTIVOS_RECEBIDO)))
            status = 'CANCELADO'
        else:
            ev.append((p['f_prep'], None, 'RECEBIDO', 'EM_PREPARACAO', p['t1'], None))
            if p['cancel'] == 'EM_PREPARACAO':
                tc = p['t1'] + timedelta(minutes=random.randint(3, 8))
            if p['cancel'] in (None, 'PRONTO'):
                ev.append((p['f_prep'], None, 'EM_PREPARACAO', 'PRONTO', p['t2'], None))
            if p['cancel'] == 'PRONTO':
                tc = p['t2'] + timedelta(minutes=random.randint(1, 4))
            if p['cancel']:
                autorizador = 2 if p['f_reg'] == 1 else 1
                ev.append((p['f_reg'], autorizador, p['cancel'], 'CANCELADO', tc,
                           random.choice(MOTIVOS_PREPARO)))
                status = 'CANCELADO'
                # insumos já usados entram no consumo do dia (perda)
                for (prod, qtd, _, _) in p['linhas']:
                    for ing, q in COMPOSICAO.get(prod, {}).items():
                        consumo_dia[d][ing] += q * qtd
            else:
                if p['tipo'] == 'RETIRADA':
                    tf = p['t2'] + timedelta(minutes=random.randint(2, 15))
                else:
                    tf = p['entrega'] + timedelta(minutes=random.randint(1, 4))
                ev.append((p['f_reg'], None, 'PRONTO', 'FINALIZADO', tf, None))
                status = 'FINALIZADO'
                p['tf'] = tf
                for (prod, qtd, _, _) in p['linhas']:
                    for ing, q in COMPOSICAO.get(prod, {}).items():
                        consumo_dia[d][ing] += q * qtd
        for e in ev:
            id_hist += 1
            historico.append((id_hist, p['id']) + e)
            ultimo_evento = max(ultimo_evento, e[3 + 1])
        pedidos.append((p['id'], p['cliente'][0], p['f_reg'],
                        None if p['cancel'] == 'RECEBIDO' else p['f_prep'],
                        p['t0'], p['tipo'], status))
        taxa = 0.0
        if p['tipo'] == 'DELIVERY' and status == 'FINALIZADO':
            id_entrega += 1
            c = p['cliente']
            taxa = AREA[c[3]][2]
            entregas.append((id_entrega, p['id'], 1, c[3], c[4], c[5], c[6], '00000-000', taxa,
                             p['saida'], p['entrega'], 'ENTREGUE'))
        if status == 'FINALIZADO':
            id_pag += 1
            forma = random.choices(['PIX', 'CARTAO_CREDITO', 'CARTAO_DEBITO', 'DINHEIRO'],
                                   [40, 25, 22, 13])[0]
            total = round(sum(q * pr for (_, q, pr, _) in p['linhas']) + taxa, 2)
            if forma == 'PIX':
                quando = p['t0'] + timedelta(minutes=1)
            else:
                quando = p['entrega'] if p['tipo'] == 'DELIVERY' else p['tf']
            pagamentos.append((id_pag, p['id'], id_fech, forma, total, quando))
    fim = ultimo_evento + timedelta(minutes=random.randint(10, 20))
    fechamentos.append((id_fech, 1 if d % 2 == 0 else 2, dia.replace(hour=18), fim,
                        'Fechamento do expediente com conferência coletiva (fictício).'))

# conferência do caixa: valor contado por forma; duas quebras de caixa propositais
esperado = defaultdict(float)
for pg in pagamentos:
    esperado[(pg[2], pg[3])] += pg[4]
QUEBRAS = {(4, 'DINHEIRO'): -5.00, (12, 'DINHEIRO'): 2.00}  # 29/10 falta R$ 5; 06/11 sobra R$ 2
id_conf = 0
for (fech, forma) in sorted(esperado):
    id_conf += 1
    conferencias.append((id_conf, fech, forma, round(esperado[(fech, forma)] + QUEBRAS.get((fech, forma), 0), 2)))

# ---------------------------------------------------------------- estoque e compras
movs = []        # (ingrediente, funcionario, item_compra, tipo, qtd, data_hora, motivo)
compras, itens_compra = [], []
saldo = {i: 0.0 for i in ING}
inicial = {1: 140, 2: 22000, 3: 4000, 4: 1800, 5: 2500, 6: 1800, 7: 2500, 8: 3000,
           9: 15000, 10: 6000, 11: 120, 12: 2200, 13: 8000}
abertura = INICIO.replace(hour=9)
for i in ING:
    movs.append((i, 3, None, 'AJUSTE_ENTRADA', inicial[i], abertura,
                 'Inventário inicial por contagem física na implantação do controle'))
    saldo[i] += inicial[i]

AJUSTES = {  # dia -> lista (ingrediente, tipo, qtd, funcionario, motivo)
    5: [(4, 'AJUSTE_SAIDA', 300, 4, 'Descarte de alface por perda de qualidade/validade')],
    6: [(6, 'AJUSTE_ENTRADA', 200, 1, 'Contagem física encontrou cebola acima do registrado')],
    7: [(1, 'AJUSTE_SAIDA', 6, 3, 'Pães danificados no transporte, descartados')],
    12: [(5, 'AJUSTE_SAIDA', 400, 4, 'Descarte de tomate por perda de qualidade/validade')],
}
BAIXO_NO_FIM = {11, 12}   # itens que terminam o período abaixo do mínimo (alerta G04)
COMPRA_DIVERGENTE = (10, 3)   # quinta 05/11, hortifruti: tomate entregue a menor
COMPRA_CANCELADA_DIA = 11     # sexta 06/11: pedido complementar à distribuidora cancelado


def custo(ing, d):
    base = CUSTO_BASE[ing]
    fator = 1 + (0.03 if d >= 7 and ing in (2, 7) else 0) + random.uniform(-0.02, 0.02)
    if ing == 5:
        fator += random.uniform(-0.08, 0.12)
    casas = 2 if base >= 1 else 4
    return round(base * fator, casas)


def proxima_entrega(forn, d):
    for x in range(d + 1, DIAS):
        if (INICIO + timedelta(days=x)).weekday() in ENTREGAS_FORNECEDOR[forn]:
            return x
    return DIAS


id_compra_seq = []   # compras recebidas (ordenadas), canceladas e pendentes depois
for d in range(DIAS):
    dia = INICIO + timedelta(days=d)
    # 1) recebimentos da manhã
    for forn in (1, 2, 3, 4):
        if dia.weekday() not in ENTREGAS_FORNECEDOR[forn]:
            continue
        nxt = proxima_entrega(forn, d)
        linhas = []
        for (ing, forn_ing) in [(i, ING[i][5]) for i in ING]:
            if forn_ing != forn:
                continue
            if ing in BAIXO_NO_FIM and d >= COMPRA_CANCELADA_DIA:
                continue  # esses itens viriam no pedido complementar que foi cancelado
            cobertura = sum(consumo_dia[x][ing] for x in range(d, nxt))
            alvo = cobertura + ING[ing][3] * 1.3
            if ing in BAIXO_NO_FIM and forn == 4 and nxt >= COMPRA_CANCELADA_DIA:
                # a reposição seguinte desses itens foi cancelada: compra cobre só até o fim com folga menor
                cobertura = sum(consumo_dia[x][ing] for x in range(d, DIAS))
                alvo = cobertura + ING[ing][3] * 0.3
            falta = alvo - saldo[ing]
            if falta <= 0:
                continue
            emb = ING[ing][4]
            qtd = math.ceil(falta / emb) * emb
            linhas.append([ing, qtd, qtd, custo(ing, d)])
        if not linhas:
            continue
        resultado, obs = 'CONFORME', 'Itens conferidos com a nota fiscal; armazenamento conforme normas sanitárias.'
        if (d, forn) == COMPRA_DIVERGENTE:
            for l in linhas:
                if l[0] == 5:
                    l[2] = round(l[1] * 0.6 / 100) * 100
            resultado = 'DIVERGENTE'
            obs = 'Tomate entregue a menor que o pedido; diferença registrada com o fornecedor (fictício).'
        compras.append(dict(forn=forn, conf=random.choice([3, 4]),
                            pedido=(dia - timedelta(days=1)).replace(hour=10, minute=random.randint(0, 50)),
                            receb=dia.replace(hour=10, minute=random.randint(0, 50)),
                            status='RECEBIDA', res=resultado, obs=obs, linhas=linhas))
        for l in linhas:
            saldo[l[0]] += l[2]
    # 2) ajustes do dia
    for (ing, tipo, q, func, motivo) in AJUSTES.get(d, []):
        movs.append((ing, func, None, tipo, q, dia.replace(hour=17, minute=30), motivo))
        saldo[ing] += q if tipo == 'AJUSTE_ENTRADA' else -q
    # 3) baixa do consumo apurado no fechamento
    fech = fechamentos[d][3] + timedelta(minutes=5)
    for ing in ING:
        q = round(consumo_dia[d][ing], 3)
        if q > 0:
            movs.append((ing, random.choice([3, 4]), None, 'SAIDA', q, fech,
                         'Baixa manual do consumo apurado no expediente'))
            saldo[ing] -= q
            assert saldo[ing] >= 0, (d, ing, saldo[ing])

# compra complementar cancelada (sem recebimento) e compra pendente para o dia seguinte ao período
dia_c = INICIO + timedelta(days=COMPRA_CANCELADA_DIA)
compras.append(dict(forn=4, conf=None, pedido=(dia_c - timedelta(days=1)).replace(hour=11),
                    receb=None, status='CANCELADA', res='PENDENTE',
                    obs='Pedido complementar cancelado: fornecedor sem estoque dos itens (fictício).',
                    linhas=[[11, 48, 0, 3.60], [12, 1000, 0, 0.083]], nf=None))
compras.append(dict(forn=2, conf=None, pedido=(INICIO + timedelta(days=DIAS - 1)).replace(hour=11),
                    receb=None, status='PENDENTE', res='PENDENTE',
                    obs='Aguardando entrega prevista para a segunda-feira seguinte (fictício).',
                    linhas=[[2, 20000, 0, 0.042], [7, 2000, 0, 0.063]], nf=None))

# numeração: compras recebidas primeiro (para o UPDATE por faixa de chave), depois cancelada e pendente
id_ic = 0
mov_compra = []
for idx, c in enumerate(compras, start=1):
    c['id'] = idx
    c['nf'] = f'NF-DEMO-{idx:04d}' if c['status'] == 'RECEBIDA' else None
    for l in c['linhas']:
        id_ic += 1
        itens_compra.append((id_ic, idx, l[0], l[1], l[2], l[3]))
        if c['status'] == 'RECEBIDA' and l[2] > 0:
            mov_compra.append((l[0], c['conf'], id_ic, 'ENTRADA', l[2], c['receb'],
                               f'Recebimento da compra {idx} (NF-DEMO-{idx:04d})'))
N_RECEBIDAS = sum(1 for c in compras if c['status'] == 'RECEBIDA')

movimentacoes = sorted(movs + mov_compra, key=lambda m: (m[5], m[2] is None, m[0]))

# ---------------------------------------------------------------- verificações (espelho das triggers/auditorias)
assert all(p[4] <= p[4] for p in pedidos)
pedidos_por_id = {p[0]: p for p in pedidos}
for e in entregas:
    assert pedidos_por_id[e[1]][5] == 'DELIVERY' and e[8] == AREA[e[3]][2] and AREA[e[3]][3] == 1
    assert e[10] >= e[9]
for pg in pagamentos:
    tot = sum(i[3] * i[4] for i in itens if i[1] == pg[1])
    tx = sum(e[8] for e in entregas if e[1] == pg[1])
    assert abs(pg[4] - (tot + tx)) < 0.01
for h in historico:
    if h[5] == 'CANCELADO':
        assert h[7] and (h[4] not in ('EM_PREPARACAO', 'PRONTO') or h[3] is not None)
assert all(i[2] != 12 for i in itens)  # RN05: produto indisponível nunca vendido
for c in compras[:N_RECEBIDAS]:
    assert c['status'] == 'RECEBIDA'

# ---------------------------------------------------------------- saída SQL


def v(x):
    if x is None:
        return 'NULL'
    if isinstance(x, datetime):
        return f"'{x:%Y-%m-%d %H:%M:%S}'"
    if isinstance(x, float):
        return f'{x:.3f}'.rstrip('0').rstrip('.') if x != int(x) else f'{int(x)}'
    if isinstance(x, int):
        return str(x)
    return "'" + str(x).replace("'", "''") + "'"


def money(x):
    return f'{x:.2f}'


out = []


def insert(tabela, colunas, linhas, bloco=400):
    for i in range(0, len(linhas), bloco):
        parte = linhas[i:i + bloco]
        out.append(f"INSERT INTO {tabela} ({', '.join(colunas)}) VALUES")
        out.append(',\n'.join('    (' + ', '.join(r) + ')' for r in parte) + ';\n')


def comment(txt):
    out.append(f'-- {txt}')


comment(f'Período simulado: {INICIO:%d/%m/%Y} a {(INICIO + timedelta(days=DIAS - 1)):%d/%m/%Y} '
        f'({DIAS} dias, {len(pedidos)} pedidos). Gerado por docs/gerador-massa/gerar_massa.py (semente fixa).')
out.append('')
insert('CATEGORIA', ['id_categoria', 'nome', 'descricao'], [[v(a), v(b), v(c)] for a, b, c in CATEGORIAS])
insert('CLIENTE', ['id_cliente', 'nome', 'telefone'], [[v(c[0]), v(c[1]), v(c[2])] for c in clientes])
insert('FORNECEDOR', ['id_fornecedor', 'nome', 'telefone', 'email'], [[v(x) for x in f] for f in FORNECEDORES])
insert('MOTOBOY', ['id_motoboy', 'nome', 'telefone'], [[v(1), v('Entregador Ficticio 01'), v('(11) 90000-2001')]])
insert('FUNCIONARIO', ['id_funcionario', 'nome', 'funcao', 'telefone', 'ativo'], [[v(x) for x in f] for f in FUNCIONARIOS])
insert('INGREDIENTE', ['id_ingrediente', 'nome', 'unidade_medida', 'estoque_minimo'],
       [[v(i[0]), v(i[1]), v(i[2]), v(i[3])] for i in INGREDIENTES])
insert('AREA_ENTREGA', ['id_area_entrega', 'bairro', 'taxa_padrao', 'ativo'],
       [[v(a[0]), v(a[1]), money(a[2]), v(a[3])] for a in AREAS])
insert('FECHAMENTO_CAIXA', ['id_fechamento', 'id_funcionario_responsavel', 'data_hora_inicio', 'data_hora_fim', 'observacao'],
       [[v(x) for x in f] for f in fechamentos])
insert('FORNECEDOR_INGREDIENTE', ['id_fornecedor', 'id_ingrediente'], [[v(a), v(b)] for a, b in FORNECEDOR_INGREDIENTE])
insert('PRODUTO', ['id_produto', 'id_categoria', 'nome', 'descricao', 'preco', 'disponivel'],
       [[v(p[0]), v(p[1]), v(p[2]), v(p[3]), money(p[4]), v(p[5])] for p in PRODUTOS])
comment(f'Compras 1 a {N_RECEBIDAS} entram como PENDENTE e passam a RECEBIDA no UPDATE da seção 5 (trigger RN20/RN21).')
comment(f'Compra {N_RECEBIDAS + 1} foi CANCELADA e a compra {N_RECEBIDAS + 2} continua PENDENTE (sem recebimento).')
insert('COMPRA', ['id_compra', 'id_fornecedor', 'id_funcionario_conferente', 'data_pedido', 'data_recebimento',
                  'numero_nota_fiscal', 'status_compra', 'resultado_conferencia', 'observacao_conferencia'],
       [[v(c['id']), v(c['forn']), v(c['conf']), v(c['pedido']), v(c['receb']), v(c['nf']),
         v('PENDENTE' if c['status'] == 'RECEBIDA' else c['status']), v(c['res']), v(c['obs'])] for c in compras])
insert('ITEM_COMPRA', ['id_item_compra', 'id_compra', 'id_ingrediente', 'quantidade_solicitada',
                       'quantidade_recebida', 'custo_unitario'],
       [[v(i[0]), v(i[1]), v(i[2]), v(float(i[3])), v(float(i[4])),
         (f'{i[5]:.2f}' if i[5] >= 1 else f'{i[5]:.4f}'.rstrip('0'))] for i in itens_compra])
insert('PRODUTO_INGREDIENTE', ['id_produto', 'id_ingrediente', 'quantidade_utilizada'],
       [[v(p), v(i), v(float(q))] for p in sorted(COMPOSICAO) for i, q in sorted(COMPOSICAO[p].items())])
insert('MOVIMENTACAO_ESTOQUE', ['id_movimentacao', 'id_ingrediente', 'id_funcionario', 'id_item_compra',
                                'tipo_movimentacao', 'quantidade', 'data_hora', 'motivo'],
       [[v(n), v(m[0]), v(m[1]), v(m[2]), v(m[3]), v(float(m[4])), v(m[5]), v(m[6])]
        for n, m in enumerate(movimentacoes, start=1)])
insert('PEDIDO', ['id_pedido', 'id_cliente', 'id_funcionario_registro', 'id_funcionario_preparo', 'data_hora',
                  'tipo_pedido', 'status'], [[v(x) for x in p] for p in pedidos])
insert('ITEM_PEDIDO', ['id_item_pedido', 'id_pedido', 'id_produto', 'quantidade', 'preco_unitario', 'observacao'],
       [[v(i[0]), v(i[1]), v(i[2]), v(i[3]), money(i[4]), v(i[5])] for i in itens])
insert('ENTREGA', ['id_entrega', 'id_pedido', 'id_motoboy', 'id_area_entrega', 'logradouro', 'numero', 'complemento',
                   'cep', 'taxa_entrega_aplicada', 'data_hora_saida', 'data_hora_entrega', 'status'],
       [[v(e[0]), v(e[1]), v(e[2]), v(e[3]), v(e[4]), v(e[5]), v(e[6]), v(e[7]), money(e[8]), v(e[9]), v(e[10]), v(e[11])]
        for e in entregas])
insert('PAGAMENTO', ['id_pagamento', 'id_pedido', 'id_fechamento', 'forma_pagamento', 'valor', 'data_hora'],
       [[v(p[0]), v(p[1]), v(p[2]), v(p[3]), money(p[4]), v(p[5])] for p in pagamentos])
insert('HISTORICO_STATUS_PEDIDO', ['id_historico', 'id_pedido', 'id_funcionario_responsavel', 'id_funcionario_autorizador',
                                   'status_anterior', 'status_novo', 'data_hora', 'motivo'],
       [[v(x) for x in h] for h in historico])
comment('Conferência coletiva do caixa por forma de pagamento. Duas diferenças são intencionais (quebra de caixa):')
comment('fechamento 4 (29/10) faltam R$ 5,00 em dinheiro; fechamento 12 (06/11) sobram R$ 2,00 em dinheiro.')
insert('CONFERENCIA_CAIXA', ['id_conferencia', 'id_fechamento', 'forma_pagamento', 'valor_contado'],
       [[v(c[0]), v(c[1]), v(c[2]), money(c[3])] for c in conferencias])

sys.stdout.write('\n'.join(out))

# resumo para documentação
resumo = {
    'pedidos': len(pedidos), 'itens_pedido': len(itens), 'entregas': len(entregas), 'pagamentos': len(pagamentos),
    'historico': len(historico), 'compras': len(compras), 'compras_recebidas': N_RECEBIDAS,
    'itens_compra': len(itens_compra), 'movimentacoes': len(movimentacoes), 'fechamentos': len(fechamentos),
    'conferencias': len(conferencias), 'clientes': len(clientes),
    'cancelados': sum(1 for p in pedidos if p[6] == 'CANCELADO'),
    'pedidos_por_dia': [sum(1 for p in pedidos if p[4].date() == (INICIO + timedelta(days=d)).date()) for d in range(DIAS)],
    'saldo_final': {ING[i][1]: round(saldo[i], 1) for i in ING},
}
print(resumo, file=sys.stderr)
