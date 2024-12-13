




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
CREATE               PROCEDURE [sankhya].[AD_STP_TGFTRF_GER_DIF] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @FIELD_NUNICO INT,
       @FIELD_SEQUENCIA INT,
       @I INT,
	   @MES VARCHAR(20),
	   @ANO INT,
	   @ARECEBER INT, 
	   @RECEBIDO INT, 
	   @DIF INT, 
	   @PORCENTAGEM INT,
	   @SEQUENCIA INT
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

		    DELETE AD_TGFRGF WHERE NUNICO = @FIELD_NUNICO;

		   WITH DADOS AS (
    SELECT AD_TGFTGF.NUNICO,
        MONTH(DTVENC) AS MES,
        YEAR(DTVENC) AS ANO,
        ROUND(SUM(VLRDESDOB), 2) AS ARECEBER,
        ROUND(SUM(CASE WHEN DHBAIXA IS NOT NULL AND MONTH(DTVENC) = MONTH(DHBAIXA) THEN VLRLIQUIDO ELSE 0 END), 2) AS RECEBIDO
    FROM AD_TGFTGF
    WHERE CODNAT IN (10010110, 10010106, 10010107, 10010101, 10010120, 10010108, 10010109, 10040104,10010308)
    AND AD_TGFTGF.NUNICO = @FIELD_NUNICO
    AND STATUS IS NULL 
    GROUP BY MONTH(DTVENC), YEAR(DTVENC),AD_TGFTGF.NUNICO)


      INSERT INTO AD_TGFRGF (NUNICO, SEQUENCIA, MES, ANO, ARECEBER,RECEBIDO,DIF,PORCENTAGEM)
	 SELECT @FIELD_NUNICO,
            ROW_NUMBER() OVER (ORDER BY MES, ANO) AS SEQUENCIA,
       CASE 
        WHEN MES = 1 THEN 'Janeiro'
        WHEN MES = 2 THEN 'Fevereiro'
        WHEN MES = 3 THEN 'Março'
        WHEN MES = 4 THEN 'Abril'
        WHEN MES = 5 THEN 'Maio'
        WHEN MES = 6 THEN 'Junho'
        WHEN MES = 7 THEN 'Julho'
        WHEN MES = 8 THEN 'Agosto'
        WHEN MES = 9 THEN 'Setembro'
        WHEN MES = 10 THEN 'Outubro'
        WHEN MES = 11 THEN 'Novembro'
        WHEN MES = 12 THEN 'Dezembro'
    END AS MES,
    ANO,
    ARECEBER,
    RECEBIDO,
    ROUND((ARECEBER - RECEBIDO),2)  AS DIF,
   ROUND(CASE 
        WHEN ARECEBER = 0 THEN 0
        ELSE (((ARECEBER - RECEBIDO)/ARECEBER) * 100)
    END,2) AS PORCENTAGEM
FROM DADOS
GROUP BY DADOS.NUNICO,DADOS.ANO,DADOS.MES,DADOS.ARECEBER,DADOS.RECEBIDO
ORDER BY ANO, SEQUENCIA
	  
           SET @I = @I + 1
       END




       SELECT @P_MENSAGEM = 'Títulos inseridos com sucesso!'



END
