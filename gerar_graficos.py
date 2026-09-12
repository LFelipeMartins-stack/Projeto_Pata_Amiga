import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import seaborn as sns
from sqlalchemy import create_engine
from config import POSTGRES_CONFIG

# -------------------------------------------------------------------------
# CONFIGURAÇÃO DE DESIGN MINIMALISTA E PADRONIZADO
# -------------------------------------------------------------------------
cfg = POSTGRES_CONFIG
ENGINE_URL = f"postgresql://{cfg['user']}:{cfg['password']}@{cfg['host']}:{cfg['port']}/{cfg['dbname']}"
engine = create_engine(ENGINE_URL)

# Estilo global minimalista com pilha de fontes universal
sns.set_theme(style="white")
plt.rcParams.update({
    'font.size': 10,
    'font.family': 'sans-serif',
    'font.sans-serif': ['DejaVu Sans', 'Liberation Sans', 'sans-serif'],
    'axes.labelsize': 11,
    'axes.titlesize': 13,
    'axes.titleweight': 'bold',
    'axes.edgecolor': '#cccccc',
    'axes.linewidth': 0.8
})

# Paleta corporativa minimalista
COLOR_PRIMARY = '#2c3e50'      # Azul-grafite principal
PALETTE_STEPS = ['#2c3e50', '#546e7a', '#78909c', '#b0bec5']  # Degradê discreto
PALETTE_COMPARE = ['#2c3e50', '#95a5a6']                      # Primário vs Secundário

# -------------------------------------------------------------------------
# GRAFICO P1: Gargalo de Entrega
# -------------------------------------------------------------------------
query_p1 = """
SELECT 
    COALESCE(l.porte, 'Sem Loja') AS porte,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2) AS separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2) AS nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2) AS despacho_entrega
FROM fato_pedido f
LEFT JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_tempo_entrega <> -1
GROUP BY COALESCE(l.porte, 'Sem Loja')
ORDER BY porte;
"""
df_p1 = pd.read_sql(query_p1, engine)
df_p1_melted = df_p1.melt(id_vars=['porte'], var_name='etapa', value_name='dias')

fig, ax = plt.subplots(figsize=(9, 4.5))
sns.barplot(data=df_p1_melted, x='porte', y='dias', hue='etapa', palette=PALETTE_STEPS, ax=ax)
ax.set_title('P1: Tempo Médio de Entrega por Etapa e Porte (Dias)', pad=15)
ax.set_xlabel('Porte da Loja')
ax.set_ylabel('Dias Úteis')
ax.grid(axis='y', linestyle='--', alpha=0.4)
ax.legend(title='', frameon=False)
sns.despine()
plt.tight_layout()
plt.savefig('grafico_p1_gargalo.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P2: Participação das Categorias
# -------------------------------------------------------------------------
query_p2 = """
SELECT 
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento
FROM fato_pedido f
JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento DESC;
"""
df_p2 = pd.read_sql(query_p2, engine)

fig, ax = plt.subplots(figsize=(8, 4.5))
sns.barplot(data=df_p2, x='faturamento', y='nome_categoria', color=COLOR_PRIMARY, ax=ax)
ax.set_title('P2: Faturamento Total por Categoria (R$)', pad=15)
ax.set_xlabel('Faturamento (R$)')
ax.set_ylabel('')
ax.grid(axis='x', linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f'{x*1e-3:,.0f}k' if x >= 1e3 else f'{x:,.0f}'))

for p in ax.patches:
    width = p.get_width()
    ax.annotate(f'R$ {width:,.2f}', (width, p.get_y() + p.get_height() / 2.),
                ha='left', va='center', xytext=(6, 0), textcoords='offset points', fontsize=9, color='#333333')

sns.despine(left=True)
plt.tight_layout()
plt.savefig('grafico_p2_categorias.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P3: Ticket Médio (Com vs Sem Desconto)
# -------------------------------------------------------------------------
query_p3 = """
SELECT 
    canal_pedido,
    ROUND(AVG(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END), 2) AS ticket_com_desconto,
    ROUND(AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END), 2) AS ticket_sem_desconto
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY ticket_com_desconto DESC;
"""
df_p3 = pd.read_sql(query_p3, engine)
df_p3_melted = df_p3.melt(id_vars=['canal_pedido'], var_name='tipo_desconto', value_name='ticket_medio')
df_p3_melted['tipo_desconto'] = df_p3_melted['tipo_desconto'].map({
    'ticket_com_desconto': 'Com Desconto',
    'ticket_sem_desconto': 'Sem Desconto'
})

fig, ax = plt.subplots(figsize=(9, 4.5))
sns.barplot(data=df_p3_melted, x='canal_pedido', y='ticket_medio', hue='tipo_desconto', palette=PALETTE_COMPARE, ax=ax)
ax.set_title('P3: Ticket Médio Com vs. Sem Desconto por Canal', pad=15)
ax.set_xlabel('Canal de Venda')
ax.set_ylabel('Ticket Médio (R$)')
ax.grid(axis='y', linestyle='--', alpha=0.4)
ax.legend(title='', frameon=False)
sns.despine()
plt.tight_layout()
plt.savefig('grafico_p3_canais.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P4: Faturamento Rateado por Praça
# -------------------------------------------------------------------------
query_p4 = """
SELECT 
    p.nome_praca,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
JOIN bridge_loja_praca b ON l.cod_loja = b.cod_loja
JOIN dim_praca p ON b.sk_praca = p.sk_praca
WHERE f.sk_loja <> -1
GROUP BY p.nome_praca
ORDER BY faturamento_rateado DESC;
"""
df_p4 = pd.read_sql(query_p4, engine)

fig, ax = plt.subplots(figsize=(9, 5))
sns.barplot(data=df_p4, x='faturamento_rateado', y='nome_praca', color=COLOR_PRIMARY, ax=ax)
ax.set_title('P4: Faturamento Rateado Proporcional por Praça (R$)', pad=15)
ax.set_xlabel('Faturamento Rateado (R$)')
ax.set_ylabel('')
ax.grid(axis='x', linestyle='--', alpha=0.4)
ax.xaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f'{x*1e-3:,.0f}k' if x >= 1e3 else f'{x:,.0f}'))

for p in ax.patches:
    width = p.get_width()
    ax.annotate(f'R$ {width:,.2f}', (width, p.get_y() + p.get_height() / 2.),
                ha='left', va='center', xytext=(6, 0), textcoords='offset points', fontsize=9, color='#333333')

sns.despine(left=True)
plt.tight_layout()
plt.savefig('grafico_p4_pracas.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P5a: Top Lojas em Itens / 1.000 Habitantes
# -------------------------------------------------------------------------
query_p5a = """
SELECT 
    l.nome_loja,
    ROUND(SUM(f.qt_itens) * 1000.0 / NULLIF(l.populacao_cidade, 0), 2) AS itens_por_mil_hab
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.sk_loja, l.nome_loja, l.populacao_cidade
ORDER BY itens_por_mil_hab DESC
LIMIT 8;
"""
df_p5a = pd.read_sql(query_p5a, engine)

fig, ax = plt.subplots(figsize=(8, 4.5))
sns.barplot(data=df_p5a, x='itens_por_mil_hab', y='nome_loja', color=COLOR_PRIMARY, ax=ax)
ax.set_title('P5a: Top Lojas em Itens Vendidos por 1.000 Hab.', pad=15)
ax.set_xlabel('Itens / 1.000 Habitantes')
ax.set_ylabel('')
ax.grid(axis='x', linestyle='--', alpha=0.4)

for p in ax.patches:
    width = p.get_width()
    ax.annotate(f'{width:,.2f}', (width, p.get_y() + p.get_height() / 2.),
                ha='left', va='center', xytext=(6, 0), textcoords='offset points', fontsize=9, color='#333333')

sns.despine(left=True)
plt.tight_layout()
plt.savefig('grafico_p5a_expansao.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P5b: Faturamento por Faixa ATUAL de Franquia (Notação Linear)
# -------------------------------------------------------------------------
query_p5b = """
SELECT 
    l.faixa_franquia,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.faixa_franquia
ORDER BY faturamento DESC;
"""
df_p5b = pd.read_sql(query_p5b, engine)

fig, ax = plt.subplots(figsize=(7.5, 4.5))
sns.barplot(data=df_p5b, x='faixa_franquia', y='faturamento', color=COLOR_PRIMARY, ax=ax)
ax.set_title('P5b: Faturamento por Faixa ATUAL de Franquia', pad=15)
ax.set_xlabel('Faixa de Franquia')
ax.set_ylabel('Faturamento (R$)')
ax.grid(axis='y', linestyle='--', alpha=0.4)

# Desativa a notação científica (1e6) e formata o eixo Y em inteiros
ax.ticklabel_format(style='plain', axis='y')
ax.yaxis.set_major_formatter(ticker.FuncFormatter(lambda x, p: f'{x*1e-3:,.0f}k' if x >= 1e3 else f'{x:,.0f}'))

for p in ax.patches:
    height = p.get_height()
    ax.annotate(f'R$ {height:,.2f}', (p.get_x() + p.get_width() / 2., height),
                ha='center', va='bottom', xytext=(0, 4), textcoords='offset points', fontsize=9, color='#333333')

sns.despine()
plt.tight_layout()
plt.savefig('grafico_p5b_franquia.png', dpi=300)
plt.close()

# -------------------------------------------------------------------------
# GRAFICO P5c: Métricas de Dados Ausentes e em Aberto
# -------------------------------------------------------------------------
query_p5c = """
SELECT 
    COUNT(*) FILTER (WHERE sk_loja = -1) AS "Pedidos sem Loja",
    COUNT(*) FILTER (WHERE sk_tempo_entrega = -1) AS "Entregas em Aberto",
    COUNT(*) FILTER (WHERE vl_liquido IS NULL) AS "Valores em Branco",
    COUNT(*) FILTER (WHERE qt_itens IS NULL) AS "Itens em Branco"
FROM fato_pedido;
"""
df_p5c = pd.read_sql(query_p5c, engine)
df_p5c_melted = df_p5c.melt(var_name='metrica', value_name='total')

fig, ax = plt.subplots(figsize=(8.5, 4.5))
sns.barplot(data=df_p5c_melted, x='metrica', y='total', color=COLOR_PRIMARY, ax=ax)
ax.set_title('P5c: Volumetria de Registros Ausentes e em Aberto', pad=15)
ax.set_xlabel('')
ax.set_ylabel('Quantidade de Pedidos')
ax.grid(axis='y', linestyle='--', alpha=0.4)

for p in ax.patches:
    height = p.get_height()
    ax.annotate(f'{int(height):,}', (p.get_x() + p.get_width() / 2., height),
                ha='center', va='bottom', xytext=(0, 4), textcoords='offset points', fontsize=9, color='#333333')

sns.despine()
plt.tight_layout()
plt.savefig('grafico_p5c_dados_ausentes.png', dpi=300)
plt.close()

print("Todos os gráficos (P1 a P5c) gerados com sucesso!")