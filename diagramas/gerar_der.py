import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, Polygon, Circle, FancyBboxPatch

W, H = 1800, 1780
fig = plt.figure(figsize=((W+40)/100, H/100), dpi=100)
ax = fig.add_axes([0, 0, 1, 1]); ax.set_xlim(-40, W); ax.set_ylim(H, 0); ax.axis("off")
INK = "#1f2933"; ENT = "#e8f0fb"; REL = "#fdf3e1"; ACC = "#2f5d8a"
FS = 12

EW, EH = 190, 70
ents = {
 "CLIENTE": (300, 520), "PEDIDO": (800, 520), "PAGAMENTO": (800, 170),
 "ENTREGA": (1400, 520), "MOTOBOY": (1400, 1080), "PRODUTO": (800, 1080),
 "CATEGORIA": (300, 1080), "INGREDIENTE": (800, 1600), "FORNECEDOR": (300, 1600),
}
RW, RH = 150, 80
rels = {
 "REALIZA": (550, 520), "POSSUI": (800, 345), "GERA": (1100, 520),
 "TRANSPORTA": (1400, 800), "CONTÉM": (800, 800), "CLASSIFICA": (550, 1080),
 "COMPÕE": (800, 1340), "FORNECE": (550, 1600),
}
def line(p, q, **k): ax.plot([p[0], q[0]], [p[1], q[1]], color=k.get("c", INK), lw=k.get("lw", 1.4), ls=k.get("ls", "-"), zorder=1)

links = [  # (ent, rel, card near entity, label offset)
 ("CLIENTE","REALIZA","(1,1)",(12,-12)), ("PEDIDO","REALIZA","(0,N)",(-62,-12)),
 ("PEDIDO","POSSUI","(1,1)",(-52,-22)), ("PAGAMENTO","POSSUI","(0,1)",(10,26)),
 ("PEDIDO","GERA","(1,1)",(12,-12)), ("ENTREGA","GERA","(0,1)",(-62,-12)),
 ("ENTREGA","TRANSPORTA","(0,N)",(10,26)), ("MOTOBOY","TRANSPORTA","(1,1)",(10,-22)),
 ("PEDIDO","CONTÉM","(0,N)",(10,26)), ("PRODUTO","CONTÉM","(1,N)",(10,-22)),
 ("CATEGORIA","CLASSIFICA","(1,1)",(12,-12)), ("PRODUTO","CLASSIFICA","(0,N)",(-62,-12)),
 ("PRODUTO","COMPÕE","(0,N)",(10,26)), ("INGREDIENTE","COMPÕE","(0,N)",(10,-22)),
 ("FORNECEDOR","FORNECE","(1,N)",(12,-12)), ("INGREDIENTE","FORNECE","(1,N)",(-62,-12)),
]
def edge_pt(ent, rel):
    (ex, ey), (rx, ry) = ents[ent], rels[rel]
    if abs(rx-ex) > abs(ry-ey): return (ex + (EW/2 if rx > ex else -EW/2), ey)
    return (ex, ey + (EH/2 if ry > ey else -EH/2))
for e, r, card, off in links:
    p = edge_pt(e, r); line(p, rels[r])
    ax.text(p[0]+off[0], p[1]+off[1], card, fontsize=FS, color=ACC, fontweight="bold", va="center", zorder=5)

for n, (x, y) in ents.items():
    ax.add_patch(Rectangle((x-EW/2, y-EH/2), EW, EH, fc=ENT, ec=INK, lw=2, zorder=3))
    ax.text(x, y, n, ha="center", va="center", fontsize=14, fontweight="bold", color=INK, zorder=4)
for n, (x, y) in rels.items():
    ax.add_patch(Polygon([(x-RW/2, y), (x, y-RH/2), (x+RW/2, y), (x, y+RH/2)], fc=REL, ec=INK, lw=1.8, zorder=3))
    ax.text(x, y, n, ha="center", va="center", fontsize=11, fontweight="bold", color=INK, zorder=4)

def attr(anchor, c, name, side="right", kind="normal"):
    line(anchor, c, lw=1.1)
    if kind == "derived":
        ax.add_patch(Circle(c, 8, fc="white", ec=INK, lw=1.3, ls="--", zorder=4))
    else:
        ax.add_patch(Circle(c, 8, fc=INK if kind == "id" else "white", ec=INK, lw=1.3, zorder=4))
    dx = 14 if side == "right" else -14
    ax.text(c[0]+dx, c[1], name, fontsize=FS, va="center", ha="left" if side == "right" else "right", color=INK, zorder=5,
            fontweight="bold" if kind == "id" else "normal", fontstyle="italic" if kind == "derived" else "normal")

def column(ent_or_pt, names, side, cx, y0, dy=30, edge=None):
    """names: list of (name, kind). anchors spread along given edge segment."""
    n = len(names)
    for i, (nm, kind) in enumerate(names):
        if edge:
            (ax0, ay0), (ax1, ay1) = edge
            t = 0.5 if n == 1 else i/(n-1)
            a = (ax0 + (ax1-ax0)*t, ay0 + (ay1-ay0)*t)
        else:
            a = ent_or_pt
        attr(a, (cx, y0 + i*dy), nm, side, kind)

def L(e): x, y = ents[e]; return x-EW/2, y
def R(e): x, y = ents[e]; return x+EW/2, y

# CLIENTE (left)
x, y = L("CLIENTE"); column(None, [("id_cliente","id"),("nome","n"),("telefone","n")], "left", x-55, y-30, edge=((x, y-22),(x, y+22)))
# PAGAMENTO (right)
x, y = R("PAGAMENTO"); column(None, [("id_pagamento","id"),("forma_pagamento","n"),("valor","n"),("data_hora","n")], "right", x+55, y-45, edge=((x, y-25),(x, y+25)))
# PEDIDO (canto superior direito)
px, py = ents["PEDIDO"]
column(None, [("id_pedido","id"),("data_hora","n"),("tipo_pedido","n"),("status","n"),("valor_total","derived")], "right", px+140, py-210, dy=30,
       edge=((px+5, py-EH/2),(px+EW/2, py-EH/2+14)))
# ENTREGA
ex, ey = ents["ENTREGA"]
end_c = (ex-20, ey-150)
attr((ex-20, ey-EH/2), end_c, "endereco_entrega", "left")
column(end_c, [("logradouro","n"),("numero","n"),("bairro","n"),("complemento","n")], "right", ex+55, ey-245, dy=28)
x, y = R("ENTREGA"); column(None, [("id_entrega","id"),("data_hora_saida","n"),("data_hora_entrega","n"),("status","n")], "right", x+55, y-40, dy=30, edge=((x, y-25),(x, y+25)))
# MOTOBOY
x, y = R("MOTOBOY"); column(None, [("id_motoboy","id"),("nome","n"),("telefone","n")], "right", x+55, y-30, edge=((x, y-22),(x, y+22)))
# PRODUTO
x, y = R("PRODUTO"); column(None, [("id_produto","id"),("nome","n"),("descricao","n"),("preco","n"),("disponivel","n")], "right", x+55, y-60, edge=((x, y-28),(x, y+28)))
# CATEGORIA
x, y = L("CATEGORIA"); column(None, [("id_categoria","id"),("nome","n"),("descricao","n")], "left", x-55, y-30, edge=((x, y-22),(x, y+22)))
# INGREDIENTE
x, y = R("INGREDIENTE"); column(None, [("id_ingrediente","id"),("nome","n"),("unidade_medida","n")], "right", x+55, y-30, edge=((x, y-22),(x, y+22)))
# FORNECEDOR
x, y = L("FORNECEDOR"); column(None, [("id_fornecedor","id"),("nome","n"),("telefone","n"),("email","n")], "left", x-55, y-45, edge=((x, y-25),(x, y+25)))
# atributos de relacionamento
rx, ry = rels["CONTÉM"]; column((rx+RW/2, ry), [("quantidade","n"),("preco_unitario","n"),("observacao","n")], "right", rx+130, ry-30)
rx, ry = rels["COMPÕE"]; column((rx+RW/2, ry), [("quantidade_utilizada","n")], "right", rx+130, ry)

ax.text(W/2, 55, "DER Conceitual — Colossal Foods", ha="center", fontsize=22, fontweight="bold", color=INK)
ax.text(W/2, 92, "Notação de Peter Chen com atributos (estilo brModelo) • cardinalidade (mín, máx)", ha="center", fontsize=13, color="#52606d")

# legenda
lx, ly = 1180, 1390
ax.add_patch(FancyBboxPatch((lx, ly), 580, 330, boxstyle="round,pad=6", fc="#f7f9fb", ec="#9aa5b1", lw=1.2, zorder=2))
ax.text(lx+20, ly+30, "Legenda", fontsize=14, fontweight="bold", color=INK)
ax.add_patch(Rectangle((lx+20, ly+55), 60, 30, fc=ENT, ec=INK, lw=1.5, zorder=4)); ax.text(lx+95, ly+70, "Entidade", fontsize=FS, va="center")
ax.add_patch(Polygon([(lx+20, ly+115), (lx+50, ly+100), (lx+80, ly+115), (lx+50, ly+130)], fc=REL, ec=INK, lw=1.5, zorder=4)); ax.text(lx+95, ly+115, "Relacionamento", fontsize=FS, va="center")
ax.add_patch(Circle((lx+50, ly+155), 8, fc=INK, ec=INK, zorder=4)); ax.text(lx+95, ly+155, "Atributo identificador", fontsize=FS, va="center")
ax.add_patch(Circle((lx+50, ly+185), 8, fc="white", ec=INK, zorder=4)); ax.text(lx+95, ly+185, "Atributo simples", fontsize=FS, va="center")
ax.add_patch(Circle((lx+50, ly+215), 8, fc="white", ec=INK, ls="--", zorder=4)); ax.text(lx+95, ly+215, "Atributo derivado (calculado)", fontsize=FS, va="center")
ax.text(lx+20, ly+255, "(mín, máx) ao lado de uma entidade = quantas ocorrências dela", fontsize=11.5, color=INK)
ax.text(lx+20, ly+280, "se associam a UMA ocorrência da entidade do outro lado.", fontsize=11.5, color=INK)
ax.text(lx+20, ly+305, "Ex.: um PEDIDO contém (1,N) PRODUTOS.", fontsize=11.5, color=ACC)

fig.savefig("DER-Colossal-Foods.png", dpi=100, facecolor="white")
