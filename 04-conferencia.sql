--  DEPOIS DO 04 - A FATO
SELECT COUNT(*) AS linhas, '4044' AS esperado FROM fato_pedido;
-- Mais que 4.044 indica JOIN duplicando; menos, JOIN descartando linha.

-- Nenhuma FK pode ser nula, e nenhuma pode apontar para chave inexistente.
SELECT 'FK nula' AS teste, COUNT(*) AS deve_ser_zero FROM fato_pedido
WHERE sk_loja IS NULL OR sk_categoria IS NULL
   OR sk_tempo_pedido IS NULL OR sk_tempo_entrega IS NULL
UNION ALL SELECT 'FK orfa (loja)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_loja d ON d.sk_loja = f.sk_loja
WHERE d.sk_loja IS NULL
UNION ALL SELECT 'FK orfa (categoria)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_categoria d ON d.sk_categoria = f.sk_categoria
WHERE d.sk_categoria IS NULL
UNION ALL SELECT 'FK orfa (tempo da entrega)', COUNT(*)
FROM fato_pedido f LEFT JOIN dim_tempo d ON d.sk_tempo = f.sk_tempo_entrega
WHERE d.sk_tempo IS NULL;

-- Estes valores nao sao zero, e estao corretos assim.
SELECT 'pedidos sem loja (na linha -1)' AS informativo, COUNT(*) AS valor,
       '3' AS esperado FROM fato_pedido WHERE sk_loja = -1
UNION ALL SELECT 'entregas ainda nao feitas (tempo na -1)', COUNT(*), '1953'
FROM fato_pedido WHERE sk_tempo_entrega = -1;

-- Ordem do CASE do canal (arquivo 04): o WhatsApp tem de aparecer na fato.
-- Se esta consulta voltar VAZIA, o CASE testou APP antes de WHATS e os pedidos
-- de WhatsApp foram parar dentro do App.
SELECT canal_pedido, COUNT(*) AS pedidos FROM fato_pedido
WHERE canal_pedido = 'WhatsApp' GROUP BY canal_pedido;

-- Periodo dos pedidos: deve ir de 01/09/2023 a 31/03/2024. Data minima ou
-- maxima fora disso indica mascara de data errada.
SELECT MIN(dt_pedido::date) AS primeiro_pedido, MAX(dt_pedido::date) AS ultimo_pedido,
       '2023-09-01 a 2024-03-31' AS esperado FROM fato_pedido;

-- Os dias nunca podem ser negativos: o processo e sequencial.
SELECT 'dias negativos' AS teste, COUNT(*) AS deve_ser_zero FROM fato_pedido
WHERE dias_integracao_separacao < 0 OR dias_separacao_nota < 0
   OR dias_nota_despacho < 0 OR dias_despacho_entrega < 0
   OR dias_total_ate_entrega < 0;
