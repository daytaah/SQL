












/* Runtime-info
Application: CadastroTelasAdicionais
Referer: http://erp.redectc.com.br:40024/mge/flex/CadastroTelasAdicionais.swf/[[DYNAMIC]]/3
ResourceID: br.com.sankhya.core.cfg.TelasPersonalizadas
service-name: AcaoProgramadaSP.createStoredProcedure
uri: /mge/service.sbr
*/
CREATE                           PROCEDURE [sankhya].[AD_STP_INT_MOV_CLI_USE] (
       @P_CODUSU INT,                -- Código do usuário logado
       @P_IDSESSAO VARCHAR(4000),    -- Identificador da execução. Serve para buscar informações dos parâmetros/campos da execução.
       @P_QTDLINHAS INT,             -- Informa a quantidade de registros selecionados no momento da execução.
       @P_MENSAGEM VARCHAR(4000) OUT -- Caso seja passada uma mensagem aqui, ela será exibida como uma informação ao usuário.
) AS
DECLARE
       @FIELD_CODMOVUSE INT,
       @FIELD_CODLOJAUSE INT,
       @FIELD_CODPARCUSE INT,
       @FIELD_TIPOMOVUSE VARCHAR(4000),
       @I INT,
	   @P_CPF	VARCHAR(14)

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
           SET @FIELD_CODMOVUSE = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODMOVUSE')
           SET @FIELD_CODLOJAUSE = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODLOJAUSE')
           SET @FIELD_CODPARCUSE = sankhya.ACT_INT_FIELD(@P_IDSESSAO, @I, 'CODPARCUSE')
           SET @FIELD_TIPOMOVUSE = sankhya.ACT_TXT_FIELD(@P_IDSESSAO, @I, 'TIPOMOVUSE')

		   IF @FIELD_TIPOMOVUSE = 'CLI'
			BEGIN 
				EXEC AD_INS_CAB_CLI_USE		@FIELD_CODMOVUSE

				EXEC AD_INS_ITE_MOV_USE		@FIELD_CODMOVUSE

				EXEC AD_INS_DIN_MOV_USE		@FIELD_CODMOVUSE

				UPDATE AD_TGFMIU SET NUNOTASNK = (SELECT MAX(NUNOTA) FROM TGFCAB (NOLOCK)  WHERE NUMCF = @FIELD_CODMOVUSE AND TIPMOV NOT IN ('V') AND DTNEG >= CONVERT(DATE,'01/01/2023',103))
				 WHERE CODMOVUSE = @FIELD_CODMOVUSE 

				SELECT @P_CPF = REPLACE(REPLACE(REPLACE(CPF,'.',''),'-',''),'/','')
				  FROM USE_CLIENTE (NOLOCK) 
				 WHERE CODIGO = @FIELD_CODPARCUSE

				UPDATE AD_TGFMIU SET CODPARCSNK = (SELECT MIN(CODPARC) FROM TGFPAR (NOLOCK) WHERE CGC_CPF = @P_CPF)
				 WHERE CODMOVUSE = @FIELD_CODMOVUSE 
			END

           SET @I = @I + 1
       END




-- <ESCREVA SEU CÓDIGO DE FINALIZAÇÃO AQUI> --



END

