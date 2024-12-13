








/* Runtime-info
Application: CadastroTelasAdicionais
Referer: http://erp.redectc.com.br:40024/mge/flex/CadastroTelasAdicionais.swf/[[DYNAMIC]]/3
ResourceID: br.com.sankhya.core.cfg.TelasPersonalizadas
service-name: TelasAdicionais.importarEntidade
uri: /mge/service.sbr
*/
/* Runtime-info
Application: CadastroTelasAdicionais
Referer: http://10.10.10.35:8280/mge/flex/CadastroTelasAdicionais.swf/[[DYNAMIC]]/3
ResourceID: br.com.sankhya.core.cfg.TelasPersonalizadas
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
CREATE                     PROCEDURE [sankhya].[AD_STP_CALC_INADIM] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @FIELD_NUNICO INT,
       @FIELD_SEQUENCIA INT,
       @I INT
BEGIN

       -- Os valores informados pelo formulário de parâmetros, podem ser obtidos com as funções:
       --     ACT_INT_PARAM
       --     ACT_DEC_PARAM
       --     ACT_TXT_PARAM
       --     ACT_DTA_PARAM
       -- Estas funções recebem 2 argumentos:
       --     ID DA SESSÃO - Identificador da execução (Obtido através de P_IDSESSAO))
       --     NOME DO PARAMETRO - Determina qual parametro deve se deseja obter.


       SET @I = 1 -- A variável "I" representa o registro corrente.
       WHILE @I <= @P_QTDLINHAS -- Este loop permite obter o valor de campos dos registros envolvidos na execução.
       BEGIN
           -- Para obter o valor dos campos utilize uma das seguintes funções:
           --     ACT_INT_FIELD (Retorna o valor de um campo tipo NUMÉRICO INTEIRO))
           --     ACT_DEC_FIELD (Retorna o valor de um campo tipo NUMÉRICO DECIMAL))
           --     ACT_TXT_FIELD (Retorna o valor de um campo tipo TEXTO),
           --     ACT_DTA_FIELD (Retorna o valor de um campo tipo DATA)
           -- Estas funções recebem 3 argumentos:
           --     ID DA SESSÃO - Identificador da execução (Obtido através do parâmetro P_IDSESSAO))
           --     NÚMERO DA LINHA - Relativo a qual linha selecionada.
           --     NOME DO CAMPO - Determina qual campo deve ser obtido.
           SET @FIELD_NUNICO = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'NUNICO')
           SET @FIELD_SEQUENCIA = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'SEQUENCIA')

		   DELETE AD_TGFCIF WHERE NUNICO = @FIELD_NUNICO;


   WITH BASE AS (
    SELECT  
        AD_TGFTGF.NUNICO,
        MONTH(DTVENC) AS MES,
        YEAR(DTVENC) AS ANO,
        ROUND(SUM(CASE 
                   WHEN DHBAIXA IS NULL THEN VLRLIQUIDO 
                   ELSE 0 
                 END), 2) AS ACORDOSINADIM,
        ROUND(SUM(CASE 
                WHEN MONTH(DHBAIXA) = MONTH(DTVENC) 
                     AND YEAR(DHBAIXA) = YEAR(DTVENC)
                THEN VLRLIQUIDO 
                ELSE 0 
              END), 2) AS ACORDOSRECMES
            FROM AD_TGFTGF 
    INNER JOIN AD_TGFIGF ON AD_TGFIGF.NUNICO = AD_TGFTGF.NUNICO
    WHERE AD_TGFTGF.CODNAT IN (10010113,10010114,10010115,10010116,10010117)
     AND AD_TGFTGF.NUNICO = @FIELD_NUNICO
	 AND STATUS IS NULL
    GROUP BY MONTH(DTVENC), YEAR(DTVENC), AD_TGFTGF.NUNICO 
),
DADOS AS (
    SELECT  
        AD_TGFTGF.NUNICO,
        MONTH(DTVENC) AS MES,
        YEAR(DTVENC) AS ANO,
        ROUND(SUM(VLRDESDOB), 2) AS ARECEBER,
        ROUND(SUM(CASE WHEN DHBAIXA IS NOT NULL AND MONTH(DTVENC) = MONTH(DHBAIXA) AND YEAR(DTVENC) = YEAR(DHBAIXA) THEN VLRLIQUIDO ELSE 0 END), 2) AS RECEBIDO
    FROM AD_TGFTGF
    WHERE CODNAT IN (10010110, 10010106, 10010107, 10010101, 10010120, 10010108, 10010109, 10040104,10010308)
      AND AD_TGFTGF.NUNICO = @FIELD_NUNICO
      AND STATUS IS NULL 
    GROUP BY MONTH(DTVENC), YEAR(DTVENC), AD_TGFTGF.NUNICO
),
ARECEBER AS (SELECT NUNICO, ROUND(SUM(DADOS.ARECEBER),2) AS SOMARECEBER
FROM DADOS
GROUP BY DADOS.NUNICO
),
TOTAL AS (SELECT AD_TGFTGF.NUNICO, 
month(DTVENC) AS MÊS,
YEAR(DTVENC) AS ANO,
ROUND(SUM(CASE 
                   WHEN DHBAIXA IS NOT NULL AND MONTH(DHBAIXA) > MONTH(DTVENC) THEN VLRLIQUIDO 
                   ELSE 0 
                 END), 2) AS RECATRASADOS,
				 ROUND(SUM(CASE 
                   WHEN (AD_TGFIGF.CODLOJA = 'F' AND CODCTABCOINT IN (35,37,36,38,371)) OR
                        (AD_TGFIGF.CODLOJA = 'P' AND CODCTABCOINT IN (44,46,328,45,47,301)) OR
                        (AD_TGFIGF.CODLOJA = 'A' AND CODCTABCOINT IN (35,37,36,38,371,44,46,328,45,47,301))
                   THEN VLRLIQUIDO 
                   ELSE 0 
                 END), 2) AS PERDAS
    FROM AD_TGFTGF 
    INNER JOIN AD_TGFIGF ON AD_TGFIGF.NUNICO = AD_TGFTGF.NUNICO
    WHERE CODNAT IN (10010110, 10010106, 10010107, 10010101, 10010120, 10010108, 10010109, 10040104,10010308,10010113,10010114,10010115,10010116,10010117)
    AND AD_TGFTGF.NUNICO = @FIELD_NUNICO
	AND STATUS IS NULL
    GROUP BY AD_TGFTGF.NUNICO,MONTH(DTVENC), YEAR(DTVENC))
INSERT INTO AD_TGFCIF (NUNICO, SEQUENCIA, MES, ANO,ACORDOSINADIM,ACORDOSRECMES,RECATRASADOS,PERDAS,DIF,DIFANTERIOR,INADIMPLENCIA)
SELECT @FIELD_NUNICO,
       ROW_NUMBER() OVER (ORDER BY DADOS.mes, DADOS.ano) AS SEQUENCIA,
    CASE 
        WHEN DADOS.MES = 1 THEN 'Janeiro'
        WHEN DADOS.MES = 2 THEN 'Fevereiro'
        WHEN DADOS.MES = 3 THEN 'Março'
        WHEN DADOS.MES = 4 THEN 'Abril'
        WHEN DADOS.MES = 5 THEN 'Maio'
        WHEN DADOS.MES = 6 THEN 'Junho'
        WHEN DADOS.MES = 7 THEN 'Julho'
        WHEN DADOS.MES = 8 THEN 'Agosto'
        WHEN DADOS.MES = 9 THEN 'Setembro'
        WHEN DADOS.MES = 10 THEN 'Outubro'
        WHEN DADOS.MES = 11 THEN 'Novembro'
        WHEN DADOS.MES = 12 THEN 'Dezembro'
    END AS MES,
    DADOS.ANO,
    BASE.ACORDOSINADIM,
    BASE.ACORDOSRECMES,
	TOTAL.RECATRASADOS,
    TOTAL.PERDAS,
    ROUND((DADOS.ARECEBER - DADOS.RECEBIDO),2) AS DIF,
              LAG(ABS(ROUND(COALESCE(DADOS.ARECEBER, 0) - COALESCE((SELECT DADOS.RECEBIDO 
                                                               FROM DADOS D 
                                                               WHERE D.MES = DADOS.MES - 1 
                                                                     AND D.ANO = DADOS.ANO
                                                                     OR (DADOS.MES = 1 
                                                                         AND D.MES = 12 
                                                                         AND D.ANO = DADOS.ANO - 1)), 0), 2)))OVER (ORDER BY DADOS.ANO, DADOS.MES) AS DIFANTERIOR,
   ROUND((ROUND((DADOS.ARECEBER - DADOS.RECEBIDO),2)+(LAG(ABS(ROUND(COALESCE(DADOS.ARECEBER, 0) - COALESCE((SELECT DADOS.RECEBIDO 
                                                               FROM DADOS D 
                                                               WHERE D.MES = DADOS.MES - 1 
                                                                     AND D.ANO = DADOS.ANO
                                                                     OR (DADOS.MES = 1 
                                                                         AND D.MES = 12 
                                                                         AND D.ANO = DADOS.ANO - 1)), 0), 2))) 
       OVER (ORDER BY DADOS.ANO, DADOS.MES))+BASE.ACORDOSINADIM-BASE.ACORDOSRECMES-TOTAL.RECATRASADOS-TOTAL.PERDAS)/ARECEBER.SOMARECEBER,2) AS INADIMPLENCIA
FROM DADOS
LEFT JOIN BASE ON BASE.NUNICO = DADOS.NUNICO AND BASE.MES = DADOS.MES AND BASE.ANO = DADOS.ANO
INNER JOIN ARECEBER ON ARECEBER.NUNICO = DADOS.NUNICO 
LEFT JOIN TOTAL ON TOTAL.NUNICO = DADOS.NUNICO AND TOTAL.MES = DADOS.MES AND TOTAL.ANO = DADOS.ANO
ORDER BY DADOS.ANO, SEQUENCIA



           SET @I = @I + 1
       END




      SELECT @P_MENSAGEM = 'Inadimplência gerada com sucesso!'



END
