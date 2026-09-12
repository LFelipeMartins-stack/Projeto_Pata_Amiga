
-- 03: CARGA DAS DIMENSÕES CUSTOM E TABELA PONTE 

-- 1. DIM_CATEGORIA 
--------------------------------------------------------------------------------------
TRUNCATE TABLE dim_categoria RESTART IDENTITY CASCADE;

INSERT INTO dim_categoria (sk_categoria, categoria_origem, nome_categoria, grupo_categoria)
VALUES (-1, 'Nao Informado', 'Nao Informado', 'Nao Informado');

INSERT INTO dim_categoria (categoria_origem, nome_categoria, grupo_categoria)
SELECT 
    "CategoriaProduto" AS categoria_origem,
    CASE 
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%MED%' THEN 'Medicamento'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%PETISC%' THEN 'Petisco'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%RA%' THEN 'Racao'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%HIG%' THEN 'Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%BRINQ%' THEN 'Brinquedo'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%ACESS%' THEN 'Acessorio'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%SERV%' THEN 'Servico'
        ELSE 'Nao Informado'
    END AS nome_categoria,
    CASE 
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%MED%' THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%PETISC%' THEN 'Saude e Higiene'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%RA%' THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%HIG%' THEN 'Alimentacao'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%BRINQ%' THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%ACESS%' THEN 'Bem-estar'
        WHEN UPPER(TRANSLATE("CategoriaProduto", 'ÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇáàâãéèêíìîóòôõúùûç', 'AAAAEEEIIIOOOOUUUCaaaaeeeiiioooouuuc')) LIKE '%SERV%' THEN 'Bem-estar'
        ELSE 'Nao Informado'
    END AS grupo_categoria
FROM stg_pedido
WHERE "CategoriaProduto" IS NOT NULL AND TRIM("CategoriaProduto") <> ''
GROUP BY "CategoriaProduto";

-- 2. DIM_PRACA 
--------------------------------------------------------------------------------------
TRUNCATE TABLE dim_praca RESTART IDENTITY CASCADE;

INSERT INTO dim_praca (sk_praca, cod_praca, nome_praca, regional, domicilios_com_pet)
VALUES (-1, 'N/I', 'Nao Informado', 'Nao Informado', NULL);

INSERT INTO dim_praca (cod_praca, nome_praca, regional, domicilios_com_pet)
SELECT DISTINCT
    "CodPraca",
    "NomePraca",
    "Regional",
    CAST(REPLACE("DomiciliosComPet", '.', '') AS INT)
FROM stg_loja_praca
WHERE "CodPraca" IS NOT NULL;


-- 3. BRIDGE_LOJA_PRACA 
--------------------------------------------------------------------------------------
TRUNCATE TABLE bridge_loja_praca;

INSERT INTO bridge_loja_praca (cod_loja, sk_praca, fator_publico)
SELECT 
    p."CodLoja",
    dp.sk_praca,
    CAST(REPLACE(p."PercentualPublico", ',', '.') AS DECIMAL(6,4))
FROM stg_loja_praca p
JOIN dim_praca dp ON p."CodPraca" = dp.cod_praca;