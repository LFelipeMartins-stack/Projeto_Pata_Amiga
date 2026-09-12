-- ARQUIVO 05: CONSULTAS DE NEGÓCIO (P1 a P5) E RECONCILIAÇÃO NUMÉRICA


-- 0. VALIDAÇÃO DE FATURAMENTO TOTAL DA REDE (Esperado: ~1.793.309)
--------------------------------------------------------------------------------------
SELECT 
    ROUND(SUM(vl_liquido), 2) AS faturamento_total_rede 
FROM fato_pedido;

-- P1: ONDE ESTÁ O GARGALO DA ENTREGA? (POR PORTE DE LOJA E ETAPAS DO PROCESSO)
--------------------------------------------------------------------------------------
SELECT 
    COALESCE(l.porte, 'Sem Loja') AS porte_loja,
    COUNT(f.sk_pedido) AS total_pedidos_entregues,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS avg_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2) AS avg_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2) AS avg_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2) AS avg_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS avg_total_ate_entrega
FROM fato_pedido f
LEFT JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_tempo_entrega <> -1 -- Considera apenas processos de entrega concluídos
GROUP BY COALESCE(l.porte, 'Sem Loja')
ORDER BY avg_total_ate_entrega DESC;


-- P2: QUAL CATEGORIA CONCENTRA O FATURAMENTO? (GERAL E POR PORTE)
--------------------------------------------------------------------------------------
-- Geral por Categoria
SELECT 
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_categoria,
    ROUND(SUM(f.vl_liquido) * 100.0 / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS pct_faturamento_total
FROM fato_pedido f
JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
GROUP BY c.nome_categoria
ORDER BY faturamento_categoria DESC;

-- Campeã por Porte de Loja
SELECT 
    l.porte,
    c.nome_categoria,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento
FROM fato_pedido f
JOIN dim_categoria c ON f.sk_categoria = c.sk_categoria
JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.porte, c.nome_categoria
ORDER BY l.porte, faturamento DESC;


-- P3: O DESCONTO FUNCIONA IGUAL EM TODO CANAL? (TICKET MÉDIO E REPRESENTATIVIDADE)
--------------------------------------------------------------------------------------
SELECT 
    f.canal_pedido,
    COUNT(f.sk_pedido) AS qtd_pedidos,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento_canal,
    ROUND(SUM(f.vl_liquido) * 100.0 / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS pct_faturamento,
    ROUND(AVG(CASE WHEN f.houve_desconto = 'Sim' THEN f.vl_liquido END), 2) AS ticket_com_desconto,
    ROUND(AVG(CASE WHEN f.houve_desconto = 'Nao' THEN f.vl_liquido END), 2) AS ticket_sem_desconto
FROM fato_pedido f
GROUP BY f.canal_pedido
ORDER BY faturamento_canal DESC;


-- P4: QUAL PRAÇA CONCENTRA O FATURAMENTO? (RATEIO N:N E DOMICÍLIOS COM PET)
--------------------------------------------------------------------------------------
SELECT 
    p.nome_praca,
    p.regional,
    p.domicilios_com_pet,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
JOIN bridge_loja_praca b ON l.cod_loja = b.cod_loja
JOIN dim_praca p ON b.sk_praca = p.sk_praca
WHERE f.sk_loja <> -1
GROUP BY p.sk_praca, p.nome_praca, p.regional, p.domicilios_com_pet
ORDER BY faturamento_rateado DESC;


-- P5: DECISÃO DE EXPANSÃO, FAIXA DE FRANQUIA E DADOS AUSENTES
--------------------------------------------------------------------------------------
-- P5a: Ranqueamento por Itens / 1.000 Habitantes vs Tempo Médio de Entrega
SELECT 
    l.nome_loja,
    l.cidade,
    l.populacao_cidade,
    SUM(f.qt_itens) AS total_itens,
    ROUND(SUM(f.qt_itens) * 1000.0 / NULLIF(l.populacao_cidade, 0), 2) AS itens_por_mil_hab,
    ROUND(AVG(f.dias_total_ate_entrega), 2) AS avg_dias_entrega
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.sk_loja, l.nome_loja, l.cidade, l.populacao_cidade
ORDER BY itens_por_mil_hab DESC;

-- P5b: Faturamento por Faixa ATUAL de Franquia (SCD Tipo 1 / Fotografia Atual)
SELECT 
    l.faixa_franquia,
    ROUND(SUM(f.vl_liquido), 2) AS faturamento
FROM fato_pedido f
JOIN dim_loja l ON f.sk_loja = l.sk_loja
WHERE f.sk_loja <> -1
GROUP BY l.faixa_franquia
ORDER BY faturamento DESC;

-- P5c: Métricas do que ficou de fora (Pedidos e Dados em Aberto)
SELECT 
    COUNT(*) FILTER (WHERE sk_loja = -1) AS pedidos_sem_loja,
    COUNT(*) FILTER (WHERE sk_tempo_entrega = -1) AS entregas_em_aberto,
    COUNT(*) FILTER (WHERE vl_liquido IS NULL) AS valores_em_branco,
    COUNT(*) FILTER (WHERE qt_itens IS NULL) AS itens_em_branco
FROM fato_pedido;


-- RECONCILIAÇÃO NUMÉRICA DO ENCARTE (Diferença entre Total e Rateado + Sem Loja = 0)
--------------------------------------------------------------------------------------
WITH total_rede AS (
    SELECT SUM(vl_liquido) AS total FROM fato_pedido
),
sem_loja AS (
    SELECT SUM(vl_liquido) AS total FROM fato_pedido WHERE sk_loja = -1
),
rateado_pracas AS (
    SELECT SUM(f.vl_liquido * b.fator_publico) AS total
    FROM fato_pedido f
    JOIN dim_loja l ON f.sk_loja = l.sk_loja
    JOIN bridge_loja_praca b ON l.cod_loja = b.cod_loja
    WHERE f.sk_loja <> -1
)
SELECT 
    ROUND((SELECT total FROM total_rede) - ((SELECT total FROM rateado_pracas) + COALESCE((SELECT total FROM sem_loja), 0)), 2) AS diferenca_esperada_zero;