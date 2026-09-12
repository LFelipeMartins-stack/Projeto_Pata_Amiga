--  DEPOIS DO 03 - AS SUAS DIMENSOES

SELECT 'dim_categoria'     AS tabela, COUNT(*) AS linhas,
       '38 no PostgreSQL - varia por banco' AS esperado FROM dim_categoria
UNION ALL SELECT 'dim_praca',         COUNT(*), '13  (12 pracas + a -1)' FROM dim_praca
UNION ALL SELECT 'bridge_loja_praca', COUNT(*), '48' FROM bridge_loja_praca;

-- ESTE e o teste que vale nota, e ele NAO muda de banco para banco.
SELECT COUNT(DISTINCT nome_categoria) AS categorias_padronizadas,
       '8 = as 7 categorias + a linha -1' AS esperado FROM dim_categoria;

-- Se aparecer 'Nao Informado' numa linha que nao e a -1, algum WHEN do CASE nao
-- classificou a grafia. A consulta deve voltar VAZIA.
SELECT categoria_origem, nome_categoria FROM dim_categoria
WHERE nome_categoria = 'Nao Informado' AND sk_categoria <> -1;

-- Ordem do CASE, teste 1: "Racao Medicamentosa" deve ser Medicamento.
-- Se aparecer 'Racao' na segunda coluna, o CASE testou RA antes de MED.
SELECT categoria_origem, nome_categoria, 'Medicamento' AS esperado
FROM dim_categoria WHERE UPPER(categoria_origem) LIKE '%MEDICAMENTOSA%';


-- A ponte: o fator deve somar 1,00 em cada loja. A consulta deve voltar VAZIA.
SELECT cod_loja, ROUND(SUM(fator_publico), 4) AS soma_dos_fatores
FROM bridge_loja_praca GROUP BY cod_loja
HAVING ROUND(SUM(fator_publico), 4) <> 1;

-- As 32 lojas devem estar na ponte, e toda praca deve ter pelo menos uma loja.
SELECT 'lojas na ponte' AS teste, COUNT(DISTINCT cod_loja) AS valor, '32' AS esperado
FROM bridge_loja_praca
UNION ALL SELECT 'pracas na ponte', COUNT(DISTINCT sk_praca), '12' FROM bridge_loja_praca;

-- Toda dimensao precisa da linha -1. As duas devem aparecer aqui.
SELECT 'dim_categoria' AS dimensao, COUNT(*) AS tem_a_linha_menos_1
FROM dim_categoria WHERE sk_categoria = -1
UNION ALL SELECT 'dim_praca',       COUNT(*) FROM dim_praca       WHERE sk_praca = -1;

--