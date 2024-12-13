
CREATE                                                           PROCEDURE [sankhya].[AD_INS_DIN_VDA_USE](   @P_NROUNICOUSE		INT)      
AS      
DECLARE    
	@P_NUNOTA  				INT,
	@P_SEQUENCIA 			INT,
	@P_CODIMP	 			INT,
	@P_CODINC	 			INT,
	@P_BASE  				FLOAT, 
	@P_BASERED				FLOAT,
	@P_VLRREPRED  			FLOAT,
	@P_PAUTA	  			FLOAT,
	@P_ALIQUOTA  			FLOAT,
	@P_VALOR				FLOAT,
	@P_TIPO					INT,
	@P_CST					INT,
	@P_COMIVA				VARCHAR(1),
	@P_DHALTER				DATE,
	@P_ALIQUOTANORMAL		FLOAT,
	@P_DIGITADO				VARCHAR(1),
	@P_TIPCALCDIFAL			INT,
	@P_CODUSU				INT,
	@EXISTE					INT,
    @P_PICMSUFDEST          FLOAT,
	@P_PICMSINTERPART       FLOAT,
	@P_VICMSUFDEST          FLOAT,
	@P_VICMSUFREMET			FLOAT,
    @P_BASEFCPINT			FLOAT,
	@P_PERCFCPINT			FLOAT,
	@P_VLRFCPINT			FLOAT,
	@P_VBCFCPUFDEST			FLOAT,
	@P_PFCPUFDEST			FLOAT,
	@P_VFCPUFDEST			FLOAT,
	@P_MAXSEQ				INT,
    @P_VLRICMSFCPINT		FLOAT,
	@P_VLRICMSFCP           FLOAT,
	@P_CFOP					INT

BEGIN      

 SELECT @P_NUNOTA = C.NUNOTA 
   FROM TGFCAB  (NOLOCK) C
  INNER JOIN TGFTOP T  (NOLOCK) ON C.CODTIPOPER = T.CODTIPOPER AND T.DHALTER = C.DHTIPOPER
  WHERE C.NUMCF = @P_NROUNICOUSE

 SELECT @P_MAXSEQ = 1
      , @P_VLRICMSFCPINT = 0
	  , @P_VLRICMSFCP = 0


 SELECT @P_MAXSEQ = MAX(I.ITEM)
      , @P_VLRICMSFCPINT = SUM(CASE WHEN SUBSTRING(F.CFOP,1,1) = '5' THEN F.VFCP ELSE 0 END)
	  , @P_VLRICMSFCP = SUM(CASE WHEN SUBSTRING(F.CFOP,1,1) = '6' THEN F.VFCPUFDEST ELSE 0 END)
   FROM USE_VENDA  (NOLOCK) C
  INNER JOIN AD_TGFLOJA L  (NOLOCK) ON C.LOJA = L.CODLOJA  
  INNER JOIN USE_ITEMVENDA  (NOLOCK) I ON C.CODIGO = I.VENDA AND C.LOJA = I.VENDALOJA
  INNER JOIN AD_TGFPROLCA  (NOLOCK) LCA ON I.PRODUTO = LCA.CODIGOPRODUTOUSE
   LEFT JOIN USE_MOVIMENTOESTSAI  (NOLOCK) M ON ISNULL(C.CODIGOANTERIOR,C.CODIGO) = M.VENDA AND C.LOJA = M.LOJAEMI AND ISNULL(M.STATUSNFE,3) = 3 AND ISNULL(M.CHAVENFE,C.CHAVENFE) IS NOT NULL
   LEFT JOIN USE_ITEMESTSAI  (NOLOCK) F ON M.LOJAEMI = F.MOVIMENTOSAILOJA AND M.CODIGO = F.MOVIMENTOSAI AND F.PRODUTO = I.PRODUTO
   LEFT JOIN USE_MOVIMENTOESTSAI  (NOLOCK) M2 ON C.CHAVENFE = M2.CHAVENFE AND C.LOJA = M2.LOJAEMI AND ISNULL(M2.STATUSNFE,3) = 3 --AND C.NOTA = M2.NOTA
   LEFT JOIN USE_ITEMESTSAI  (NOLOCK) F2 ON M2.LOJAEMI = F2.MOVIMENTOSAILOJA AND M2.CODIGO = F2.MOVIMENTOSAI AND F2.PRODUTO = I.PRODUTO
  WHERE /*L.ATIVO = 'S'  
    AND*/ L.CODFRANQ = 1 -- LOJAS PROPRIAS
	AND C.CODIGO = @P_NROUNICOUSE
--	AND C.DATAEXC IS NULL
	

		/*INSERIR OUTROS IMPOSTOS DA NOTA*/
		DECLARE CURSOR_AD_INS_DIN_VDA_USE CURSOR LOCAL FAST_FORWARD FOR   
		/*BLOCO ICMS*/
		SELECT DISTINCT C.CODIGO -- BASE PARA O NUNOTA (AD_NROUNICOUSE NA TGFCAB)
			 , I.ITEM AS SEQUENCIA
			 , 1 AS CODIMP -- ICMS
			 , 1 AS CODINC -- NO PRODUTO
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0) AS BASE
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0) AS BASERED
			 , 0 AS VLRREPRED
			 , 0 AS PAUTA
			 , ISNULL(ISNULL(F.ICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F.PFCP ELSE 0 END,0),F2.ICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F2.PFCP ELSE 0 END,0)),0) AS ALIQUOTA
			 , ISNULL(ISNULL(F.VLRICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F.VFCP ELSE 0 END,0),F2.VLRICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F2.VFCP ELSE 0 END,0)),0) AS VALOR
			 , 0 AS TIPO
			 , ISNULL(ISNULL(SUBSTRING(F.SITTRIBUTARIAICMS,2,3),SUBSTRING(F2.SITTRIBUTARIAICMS,2,3)),0) AS CST
			 , 'N' AS COMIVA
			 , 0 AS CODUSU
			 , GETDATE() AS DHALTER
			 , NULL AS ALIQUOTANORMAL
			 , 'N' AS DIGITADO
			 , 0 AS TIPCALCDIFAL
			 , ISNULL(ISNULL(F.PICMSUFDEST,F2.PICMSUFDEST),0)
			 , ISNULL(ISNULL(F.PICMSINTERPART,F2.PICMSINTERPART),0)
			 , ISNULL(ISNULL(F.VICMSUFDEST,F2.VICMSUFDEST),0)
			 , ISNULL(ISNULL(F.VICMSUFREMET,F2.VICMSUFREMET),0)
			 , ISNULL(ISNULL(F.VBCFCP,F2.VBCFCP),0)
		     , ISNULL(ISNULL(F.PFCP,F2.PFCP),0)
			 , ISNULL(ISNULL(F.VFCP,F2.VFCP),0)
			 , ISNULL(ISNULL(F.VBCFCPUFDEST,F2.VBCFCPUFDEST),0)
			 , ISNULL(ISNULL(F.PFCPUFDEST,F2.PFCPUFDEST),0)
			 , ISNULL(ISNULL(F.VFCPUFDEST,F2.VFCPUFDEST),0)
			 , ISNULL(ISNULL(F.CFOP,F2.CFOP),0)
		  FROM USE_VENDA  (NOLOCK) C
		 INNER JOIN AD_TGFLOJA L  (NOLOCK) ON C.LOJA = L.CODLOJA  
		 INNER JOIN TSIEMP (NOLOCK) EMP ON L.CODEMP = EMP.CODEMP
		 INNER JOIN TSICID (NOLOCK) CID ON EMP.CODCID = CID.CODCID
		 INNER JOIN TSIUFS (NOLOCK) UFS ON UFS.CODUF = CID.UF
		 INNER JOIN USE_ITEMVENDA  (NOLOCK) I ON C.CODIGO = I.VENDA AND C.LOJA = I.VENDALOJA
		 INNER JOIN AD_TGFPROLCA  (NOLOCK) LCA ON I.PRODUTO = LCA.CODIGOPRODUTOUSE
		 --INNER JOIN USE_MOVIMENTOESTSAI M ON C.CODIGO = M.VENDA AND C.LOJA = M.LOJAEMI AND M.STATUSNFE = 3  
		  LEFT JOIN USE_MOVIMENTOESTSAI  (NOLOCK) M ON ISNULL(C.CODIGOANTERIOR,C.CODIGO) = M.VENDA AND C.LOJA = M.LOJAEMI AND ISNULL(M.STATUSNFE,3) = 3  
		  LEFT JOIN USE_ITEMESTSAI  (NOLOCK) F ON M.LOJAEMI = F.MOVIMENTOSAILOJA AND M.CODIGO = F.MOVIMENTOSAI AND F.PRODUTO = I.PRODUTO
	      LEFT JOIN USE_MOVIMENTOESTSAI  (NOLOCK) M2 ON C.CHAVENFE = M2.CHAVENFE AND C.LOJA = M2.LOJAEMI AND ISNULL(M2.STATUSNFE,3) = 3 --AND C.NOTA = M2.NOTA
		  LEFT JOIN USE_ITEMESTSAI  (NOLOCK) F2 ON M2.LOJAEMI = F2.MOVIMENTOSAILOJA AND M2.CODIGO = F2.MOVIMENTOSAI AND F2.PRODUTO = I.PRODUTO
		 WHERE /*L.ATIVO = 'S'  
		   AND*/ L.CODFRANQ = 1 -- LOJAS PROPRIAS
		   AND C.CODIGO = @P_NROUNICOUSE
		   AND C.DATAEXC IS NULL
		   AND ISNULL(M.CHAVENFE,C.CHAVENFE) IS NOT NULL
		UNION ALL
		/*BLOCO PIS*/
		SELECT DISTINCT C.CODIGO -- BASE PARA O NUNOTA (AD_NROUNICOUSE NA TGFCAB)
			 , I.ITEM AS SEQUENCIA
			 , 6 AS CODIMP -- PIS
			 , 0 AS CODINC -- NO GERAL
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0) AS BASE
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0) AS BASERED
			 , 0 AS VLRREPRED
			 , 0 AS PAUTA
			 , ISNULL(ISNULL(F.PIS,F2.PIS),0) AS ALIQUOTA
			 , ROUND((ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0)) * ISNULL(ISNULL(F.PIS,F2.PIS),0)/100,2) AS VALOR
			 , 0 AS TIPO
			 , ISNULL(ISNULL(F.SITTRIBUTARIAPIS,F2.SITTRIBUTARIAPIS),0) AS CST
			 , 'N' AS COMIVA
			 , 0 AS CODUSU
			 , GETDATE() AS DHALTER
			 , ISNULL(ISNULL(F.PIS,F2.PIS),0)  AS ALIQUOTANORMAL
			 , 'N' AS DIGITADO
			 , 0 AS TIPCALCDIFAL
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
		  FROM USE_VENDA (NOLOCK) C
		 INNER JOIN AD_TGFLOJA (NOLOCK)  L ON C.LOJA = L.CODLOJA  
		 INNER JOIN TSIEMP (NOLOCK) EMP ON L.CODEMP = EMP.CODEMP
		 INNER JOIN TSICID (NOLOCK) CID ON EMP.CODCID = CID.CODCID
		 INNER JOIN TSIUFS (NOLOCK) UFS ON UFS.CODUF = CID.UF
		 INNER JOIN USE_ITEMVENDA (NOLOCK)  I ON C.CODIGO = I.VENDA AND C.LOJA = I.VENDALOJA
		 INNER JOIN AD_TGFPROLCA (NOLOCK)  LCA ON I.PRODUTO = LCA.CODIGOPRODUTOUSE
		 --INNER JOIN USE_MOVIMENTOESTSAI M ON C.CODIGO = M.VENDA AND C.LOJA = M.LOJAEMI AND M.STATUSNFE = 3 
		  LEFT JOIN USE_MOVIMENTOESTSAI (NOLOCK)  M ON ISNULL(C.CODIGOANTERIOR,C.CODIGO) = M.VENDA AND C.LOJA = M.LOJAEMI AND M.STATUSNFE = 3  
		  LEFT JOIN USE_ITEMESTSAI (NOLOCK)  F ON M.LOJAEMI = F.MOVIMENTOSAILOJA AND M.CODIGO = F.MOVIMENTOSAI AND F.PRODUTO = I.PRODUTO
	      LEFT JOIN USE_MOVIMENTOESTSAI (NOLOCK)  M2 ON C.CHAVENFE = M2.CHAVENFE AND C.LOJA = M2.LOJAEMI AND ISNULL(M2.STATUSNFE,3) = 3 --AND C.NOTA = M2.NOTA
		  LEFT JOIN USE_ITEMESTSAI (NOLOCK)  F2 ON M2.LOJAEMI = F2.MOVIMENTOSAILOJA AND M2.CODIGO = F2.MOVIMENTOSAI AND F2.PRODUTO = I.PRODUTO
		 WHERE /*L.ATIVO = 'S'  
		   AND*/ L.CODFRANQ = 1 -- LOJAS PROPRIAS
		   AND C.CODIGO = @P_NROUNICOUSE
		   AND C.DATAEXC IS NULL
		   AND ISNULL(M.CHAVENFE,C.CHAVENFE) IS NOT NULL
		UNION ALL
		/*BLOCO COFINS*/
		SELECT DISTINCT C.CODIGO -- BASE PARA O NUNOTA (AD_NROUNICOUSE NA TGFCAB)
			 , I.ITEM AS SEQUENCIA
			 , 7 AS CODIMP -- COFINS
			 , 0 AS CODINC -- NO GERAL
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0) AS BASE
			 , ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0) AS BASERED
			 , 0 AS VLRREPRED
			 , 0 AS PAUTA
			 , ISNULL(ISNULL(F.COFINS,F2.COFINS),0) AS ALIQUOTA
			 , ROUND((ISNULL(ISNULL(F.VLRBCICMS,F2.VLRBCICMS),0)-ISNULL(ISNULL(F.VLRICMS,F2.VLRICMS),0)) * ISNULL(ISNULL(F.COFINS,F2.COFINS),0)/100,2) AS VALOR
			 , 0 AS TIPO
			 , ISNULL(ISNULL(F.SITTRIBUTARIACOFINS,F2.SITTRIBUTARIACOFINS),0) AS CST
			 , 'N' AS COMIVA
			 , 0 AS CODUSU
			 , GETDATE() AS DHALTER
			 , ISNULL(ISNULL(F.COFINS,F2.COFINS),0)  AS ALIQUOTANORMAL
			 , 'N' AS DIGITADO
			 , 0 AS TIPCALCDIFAL
			 , 0
			 , 0
			 , 0
			 , 0
             , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
			 , 0
		  FROM USE_VENDA (NOLOCK) C
		 INNER JOIN AD_TGFLOJA (NOLOCK)  L ON C.LOJA = L.CODLOJA  
		 INNER JOIN TSIEMP (NOLOCK) EMP ON L.CODEMP = EMP.CODEMP
		 INNER JOIN TSICID (NOLOCK) CID ON EMP.CODCID = CID.CODCID
		 INNER JOIN TSIUFS (NOLOCK) UFS ON UFS.CODUF = CID.UF
		 INNER JOIN USE_ITEMVENDA (NOLOCK)  I ON C.CODIGO = I.VENDA AND C.LOJA = I.VENDALOJA
		 INNER JOIN AD_TGFPROLCA (NOLOCK)  LCA ON I.PRODUTO = LCA.CODIGOPRODUTOUSE
		 --INNER JOIN USE_MOVIMENTOESTSAI M ON C.CODIGO = M.VENDA AND C.LOJA = M.LOJAEMI AND M.STATUSNFE = 3 
		  LEFT JOIN USE_MOVIMENTOESTSAI (NOLOCK)  M ON ISNULL(C.CODIGOANTERIOR,C.CODIGO) = M.VENDA AND C.LOJA = M.LOJAEMI AND M.STATUSNFE = 3  
		  LEFT JOIN USE_ITEMESTSAI (NOLOCK)  F ON M.LOJAEMI = F.MOVIMENTOSAILOJA AND M.CODIGO = F.MOVIMENTOSAI AND F.PRODUTO = I.PRODUTO
	      LEFT JOIN USE_MOVIMENTOESTSAI (NOLOCK)  M2 ON C.CHAVENFE = M2.CHAVENFE AND C.LOJA = M2.LOJAEMI AND ISNULL(M2.STATUSNFE,3) = 3 --AND C.NOTA = M2.NOTA
		  LEFT JOIN USE_ITEMESTSAI (NOLOCK)  F2 ON M2.LOJAEMI = F2.MOVIMENTOSAILOJA AND M2.CODIGO = F2.MOVIMENTOSAI AND F2.PRODUTO = I.PRODUTO
		 WHERE /*L.ATIVO = 'S'  
		   AND*/ L.CODFRANQ = 1 -- LOJAS PROPRIAS
		   AND C.CODIGO = @P_NROUNICOUSE
		   AND C.DATAEXC IS NULL
		   AND ISNULL(M.CHAVENFE,C.CHAVENFE) IS NOT NULL


  
			OPEN CURSOR_AD_INS_DIN_VDA_USE  
			FETCH NEXT FROM CURSOR_AD_INS_DIN_VDA_USE INTO			@P_NROUNICOUSE,@P_SEQUENCIA,@P_CODIMP,@P_CODINC,@P_BASE,@P_BASERED,@P_VLRREPRED,
																	@P_PAUTA,@P_ALIQUOTA,@P_VALOR,@P_TIPO,@P_CST,@P_COMIVA,@P_CODUSU,@P_DHALTER,
																	@P_ALIQUOTANORMAL,@P_DIGITADO,@P_TIPCALCDIFAL,@P_PICMSUFDEST,@P_PICMSINTERPART,
			                                                        @P_VICMSUFDEST, @P_VICMSUFREMET,@P_BASEFCPINT,@P_PERCFCPINT,@P_VLRFCPINT,
																	@P_VBCFCPUFDEST,@P_PFCPUFDEST,@P_VFCPUFDEST,@P_CFOP
			

			WHILE @@FETCH_STATUS = 0  
			BEGIN  
 
				SELECT @EXISTE = COUNT(1)
				  FROM TGFDIN (NOLOCK)
				 WHERE NUNOTA = @P_NUNOTA
				   AND SEQUENCIA = @P_SEQUENCIA
				   AND CODIMP = @P_CODIMP

				--EXEC SNK_ERROR @P_CFOP



				IF @EXISTE = 0

					BEGIN

						INSERT INTO TGFDIN
						   (NUNOTA,SEQUENCIA,CODIMP,CODINC,	BASE,BASERED,VLRREPRED,PAUTA,ALIQUOTA,VALOR,			
							TIPO,CST,COMIVA,CODUSU,DHALTER,ALIQUOTANORMAL,DIGITADO,TIPCALCDIFAL,
							ALIQINTDEST,PERCPARTDIFAL,VLRDIFALDEST,VLRDIFALREM,
							BASEFCPINT,
							PERCFCPINT,
							VLRFCPINT,
							BASEFCP,
							PERCFCP,
							VLRFCP,
							PERCVLR)
						VALUES
						   (@P_NUNOTA,@P_SEQUENCIA,@P_CODIMP,@P_CODINC,@P_BASE,@P_BASERED,@P_VLRREPRED,@P_PAUTA,@P_ALIQUOTA,@P_VALOR,
							@P_TIPO,@P_CST,@P_COMIVA,@P_CODUSU,@P_DHALTER,@P_ALIQUOTANORMAL,@P_DIGITADO,@P_TIPCALCDIFAL,
						    @P_PICMSUFDEST,@P_PICMSINTERPART,@P_VICMSUFDEST, @P_VICMSUFREMET,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 5 THEN @P_BASEFCPINT ELSE 0 END,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 5 THEN @P_PERCFCPINT ELSE 0 END,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 5 THEN @P_VLRFCPINT ELSE 0 END,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 6 THEN @P_VBCFCPUFDEST ELSE 0 END,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 6 THEN @P_PFCPUFDEST ELSE 0 END,
							CASE WHEN SUBSTRING(CONVERT(CHAR,@P_CFOP),1,1) = 6 THEN @P_VFCPUFDEST ELSE 0 END,
							'P')
					
					END
						
				IF @P_SEQUENCIA = @P_MAXSEQ 
					BEGIN

						UPDATE TGFCAB SET VLRICMSFCPINT = @P_VLRICMSFCPINT 
						                , VLRICMSFCP = @P_VLRICMSFCP 
										, VLRICMS = (SELECT SUM(I.VLRICMS) FROM TGFITE (NOLOCK) I WHERE I.NUNOTA = @P_NUNOTA)
						 WHERE NUNOTA = @P_NUNOTA                       

					END

	
				FETCH NEXT FROM CURSOR_AD_INS_DIN_VDA_USE INTO 	@P_NROUNICOUSE,@P_SEQUENCIA,@P_CODIMP,@P_CODINC,@P_BASE,@P_BASERED,@P_VLRREPRED,
																@P_PAUTA,@P_ALIQUOTA,@P_VALOR,@P_TIPO,@P_CST,@P_COMIVA,@P_CODUSU,@P_DHALTER,
																@P_ALIQUOTANORMAL,@P_DIGITADO,@P_TIPCALCDIFAL,@P_PICMSUFDEST,@P_PICMSINTERPART,
			                                                    @P_VICMSUFDEST, @P_VICMSUFREMET,@P_BASEFCPINT,@P_PERCFCPINT,@P_VLRFCPINT,
																@P_VBCFCPUFDEST,@P_PFCPUFDEST,@P_VFCPUFDEST,@P_CFOP
			END  
  
			CLOSE CURSOR_AD_INS_DIN_VDA_USE  
			DEALLOCATE CURSOR_AD_INS_DIN_VDA_USE 



            
END 
