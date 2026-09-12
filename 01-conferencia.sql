SELECT 'stg_pedido'     AS tabela, COUNT(*) AS linhas, 4044 AS esperado FROM stg_pedido
UNION ALL SELECT 'stg_loja',       COUNT(*), 32 FROM stg_loja
UNION ALL SELECT 'stg_loja_praca', COUNT(*), 48 FROM stg_loja_praca;

-- Diagnostico da Tarefa 1. Estes numeros vao para o README.
SELECT 'grafias distintas de categoria (no PostgreSQL)' AS diagnostico,
       COUNT(DISTINCT "CategoriaProduto") AS valor, '37' AS esperado FROM stg_pedido
UNION ALL SELECT 'grafias distintas de nome de loja',
       COUNT(DISTINCT "Loja-Nome"), '(conte e descreva)' FROM stg_pedido
UNION ALL SELECT 'grafias distintas de HouveDesconto',
       COUNT(DISTINCT "HouveDesconto"), '(conte)' FROM stg_pedido
UNION ALL SELECT 'grafias distintas de CanalPedido',
       COUNT(DISTINCT "CanalPedido"), '(conte)' FROM stg_pedido
UNION ALL SELECT 'pedidos sem Cod Loja preenchido',
       SUM(CASE WHEN "Cod Loja" = '' THEN 1 ELSE 0 END), '1575  (~39%)' FROM stg_pedido
UNION ALL SELECT 'pedidos sem nome de loja (vao para a -1)',
       SUM(CASE WHEN "Loja-Nome" = '' THEN 1 ELSE 0 END), '3' FROM stg_pedido;

-- Os quatro marcos em branco = processo em aberto. Vao virar dias NULL.
SELECT 'Dt Separacao Estoque' AS marco,
       SUM(CASE WHEN "Dt Separacao Estoque" = '' THEN 1 ELSE 0 END) AS em_branco,
       1077 AS esperado FROM stg_pedido
UNION ALL SELECT 'DtNotaFiscal',
       SUM(CASE WHEN "DtNotaFiscal" = '' THEN 1 ELSE 0 END), 1338 FROM stg_pedido
UNION ALL SELECT 'Dt_Despacho_Transportadora',
       SUM(CASE WHEN "Dt_Despacho_Transportadora" = '' THEN 1 ELSE 0 END), 1665 FROM stg_pedido
UNION ALL SELECT 'DtEntregaCliente',
       SUM(CASE WHEN "DtEntregaCliente" = '' THEN 1 ELSE 0 END), 1953 FROM stg_pedido;

-- Conferencia da mascara de data. Rode antes de escrever a fato.
-- A data do pedido esta no formato americano ('MM/DD/YYYY'): esta contagem deve
-- dar 4044. A mascara brasileira ('DD/MM/YYYY') nao serve - e no PostgreSQL ela
-- nao devolve NULL: ela LANCA ERRO nas datas com mes maior que 12. O erro
-- aparece na hora, e e esse o aviso.
SELECT COUNT(*) AS mascara_americana_ok, '4044' AS esperado
FROM stg_pedido
WHERE TO_TIMESTAMP("DtHoraPedido", 'MM/DD/YYYY HH12:MI AM') IS NOT NULL;