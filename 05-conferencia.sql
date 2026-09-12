=====================================================================================
--  DEPOIS DO 05 - AS RESPOSTAS
-- =====================================================================================
-- Confira que a soma da tabela fecha com o total da fato. Se nao fechar, algum
-- JOIN esta descartando linha.
SELECT
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido)             AS total_na_fato,
    (SELECT ROUND(SUM(f.vl_liquido)) FROM fato_pedido f
       JOIN dim_categoria c ON c.sk_categoria = f.sk_categoria)  AS total_pela_P2;
-- As duas colunas devem dar o mesmo numero.

-- Rateio da P4: com o fator, a soma por praca mais os pedidos sem loja fecha
-- com o total da rede. A ultima coluna deve dar ZERO.
-- A diferenca e arredondada UMA vez (nao cada soma em separado): assim o
-- arredondamento nao deixa sobrar 1 ou 2 reais que na verdade fecham exato.
SELECT
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido) AS total_da_rede,
    (SELECT ROUND(SUM(f.vl_liquido * b.fator_publico))
       FROM fato_pedido f
       JOIN dim_loja l ON l.sk_loja = f.sk_loja
       JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja) AS soma_rateada,
    (SELECT ROUND(SUM(vl_liquido)) FROM fato_pedido WHERE sk_loja = -1) AS sem_loja,
    ROUND(
        (SELECT SUM(vl_liquido) FROM fato_pedido)
        - (SELECT SUM(f.vl_liquido * b.fator_publico)
             FROM fato_pedido f
             JOIN dim_loja l ON l.sk_loja = f.sk_loja
             JOIN bridge_loja_praca b ON b.cod_loja = l.cod_loja)
        - (SELECT SUM(vl_liquido) FROM fato_pedido WHERE sk_loja = -1)
    )                                                AS tem_de_dar_ZERO;
