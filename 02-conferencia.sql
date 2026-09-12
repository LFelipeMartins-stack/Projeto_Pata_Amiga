SELECT 'dim_tempo' AS tabela, COUNT(*) AS linhas, '236  (235 dias + a -1)' AS esperado
FROM dim_tempo
UNION ALL SELECT 'dim_loja', COUNT(*), '33  (32 lojas + a -1)' FROM dim_loja;

-- As quatro tabelas ja existem e estao VAZIAS. Todas devem dar zero.
SELECT 'dim_categoria' AS tabela, COUNT(*) AS deve_estar_vazia FROM dim_categoria
UNION ALL SELECT 'dim_praca',         COUNT(*) FROM dim_praca
UNION ALL SELECT 'bridge_loja_praca', COUNT(*) FROM bridge_loja_praca
UNION ALL SELECT 'fato_pedido',       COUNT(*) FROM fato_pedido;
