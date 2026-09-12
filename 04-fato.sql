-- ARQUIVO 04: CARGA DA TABELA FATO (fato_pedido) 
-- =====================================================================================
TRUNCATE TABLE fato_pedido RESTART IDENTITY CASCADE;

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT 
    p."NumeroPedido" AS numero_pedido,
    
    -- 1. FK Tempo Pedido (Formato MM/DD/YYYY HH12:MI AM -> YYYYMMDD)
    CAST(TO_CHAR(TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM'), 'YYYYMMDD') AS INT) AS sk_tempo_pedido,
    
    -- 2. FK Tempo Entrega (-1 se em aberto, vazio ou '-')
    COALESCE(
        CASE 
            WHEN TRIM(p."DtEntregaCliente") IN ('', '-') OR p."DtEntregaCliente" IS NULL THEN NULL
            ELSE CAST(TO_CHAR(p."DtEntregaCliente"::date, 'YYYYMMDD') AS INT)
        END,
        -1
    ) AS sk_tempo_entrega,
    
    -- 3. FK Loja (Lookup por Código com TRIM ou Tratamento Padronizado do Nome)
    COALESCE(l.sk_loja, -1) AS sk_loja,
    
    -- 4. FK Categoria (Lookup exato pela grafia crua da origem)
    COALESCE(c.sk_categoria, -1) AS sk_categoria,
    
    -- 5. Padronização de Houve Desconto
    CASE 
        WHEN UPPER(TRIM(p."HouveDesconto")) IN ('S', 'SIM', '1', 'X', 'TRUE', 'V') THEN 'Sim'
        WHEN UPPER(TRIM(p."HouveDesconto")) IN ('N', 'NAO', '0', 'FALSE', 'F') THEN 'Nao'
        ELSE 'Nao Informado'
    END AS houve_desconto,
    
    -- 6. Padronização do Canal (A ORDEM IMPORTA: WHATS antes de APP)
    CASE 
        WHEN UPPER(TRANSLATE(p."CanalPedido", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%WHATS%' THEN 'WhatsApp'
        WHEN UPPER(TRANSLATE(p."CanalPedido", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%APP%' THEN 'App'
        WHEN UPPER(TRANSLATE(p."CanalPedido", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%SITE%' THEN 'Site'
        WHEN UPPER(TRANSLATE(p."CanalPedido", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%LOJA%' THEN 'Loja Fisica'
        WHEN UPPER(TRANSLATE(p."CanalPedido", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%TEL%' THEN 'Telefone'
        ELSE 'Nao Informado'
    END AS canal_pedido,
    
    -- 7. Timestamp do Pedido
    TO_TIMESTAMP(p."DtHoraPedido", 'MM/DD/YYYY HH12:MI AM') AS dt_pedido,
    
    -- 8. Quantidade de Itens (Vazio ou '-' vira NULL)
    CASE 
        WHEN TRIM(p."QTD.Itens") IN ('', '-') OR p."QTD.Itens" IS NULL THEN NULL 
        ELSE CAST(TRIM(p."QTD.Itens") AS INT) 
    END AS qt_itens,
    
    -- 9. Valor Líquido (Tratamento Monetário em Reais)
    CASE 
        WHEN TRIM(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', '')) IN ('', '-') OR p."ValorLiquidoPedido(R$)" IS NULL THEN NULL
        WHEN p."ValorLiquidoPedido(R$)" LIKE '%,%' THEN 
            CAST(REPLACE(REPLACE(REPLACE(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', ''), ' ', ''), '.', ''), ',', '.') AS DECIMAL(15,2))
        ELSE 
            CAST(REPLACE(REPLACE(p."ValorLiquidoPedido(R$)", 'R$', ''), ' ', '') AS DECIMAL(15,2))
    END AS vl_liquido,
    
    -- 10. Lags do Processo (em Dias - NULL quando marco final não aconteceu ou é '-')
    CASE 
        WHEN TRIM(p."Dt Separacao Estoque") IN ('', '-') OR p."Dt Separacao Estoque" IS NULL THEN NULL
        ELSE p."Dt Separacao Estoque"::date - TO_TIMESTAMP(p."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date 
    END AS dias_integracao_separacao,

    CASE 
        WHEN TRIM(p."DtNotaFiscal") IN ('', '-') OR p."DtNotaFiscal" IS NULL 
          OR TRIM(p."Dt Separacao Estoque") IN ('', '-') OR p."Dt Separacao Estoque" IS NULL THEN NULL
        ELSE p."DtNotaFiscal"::date - p."Dt Separacao Estoque"::date 
    END AS dias_separacao_nota,

    CASE 
        WHEN TRIM(p."Dt_Despacho_Transportadora") IN ('', '-') OR p."Dt_Despacho_Transportadora" IS NULL 
          OR TRIM(p."DtNotaFiscal") IN ('', '-') OR p."DtNotaFiscal" IS NULL THEN NULL
        ELSE p."Dt_Despacho_Transportadora"::date - p."DtNotaFiscal"::date 
    END AS dias_nota_despacho,

    CASE 
        WHEN TRIM(p."DtEntregaCliente") IN ('', '-') OR p."DtEntregaCliente" IS NULL 
          OR TRIM(p."Dt_Despacho_Transportadora") IN ('', '-') OR p."Dt_Despacho_Transportadora" IS NULL THEN NULL
        ELSE p."DtEntregaCliente"::date - p."Dt_Despacho_Transportadora"::date 
    END AS dias_despacho_entrega,

    CASE 
        WHEN TRIM(p."DtEntregaCliente") IN ('', '-') OR p."DtEntregaCliente" IS NULL THEN NULL
        ELSE p."DtEntregaCliente"::date - TO_TIMESTAMP(p."DtHoraIntegracaoERP", 'MM/DD/YYYY HH12:MI AM')::date 
    END AS dias_total_ate_entrega

FROM stg_pedido p

-- JOIN Categoria pela grafia crua
LEFT JOIN dim_categoria c 
    ON p."CategoriaProduto" = c.categoria_origem

-- JOIN Loja (Primeiro UPPER + TRANSLATE, depois REPLACE do /SC e dos apelidos)
LEFT JOIN dim_loja l 
    ON TRIM(p."Cod Loja") = l.cod_loja 
    OR REPLACE(
        REPLACE(
            REPLACE(
                TRIM(
                    REPLACE(
                        REPLACE(
                            UPPER(TRANSLATE(p."Loja-Nome", 'áàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')),
                        '/SC', ''),
                    '  ', ' ')
                ),
            'PATA AMIGA BLUMENAL CENTRO', 'PATA AMIGA BLUMENAU CENTRO'),
        'PATA AMIGA FLORIPA NORTE', 'PATA AMIGA FLORIANOPOLIS NORTE'),
    'PATA AMIGA JGUA DO SUL', 'PATA AMIGA JARAGUA DO SUL') = l.chave_loja;