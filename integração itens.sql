



















CREATE                                             PROCEDURE [sankhya].[AD_INS_ITE_MOV_USE]( @P_NROUNICOUSE		INT)      
AS      
DECLARE    
	@P_NUNOTA  		INT,  
	@P_CODTIPOPER 	INT, 
	@P_CODPROD_ITE 			INT,
	@P_CONTROLE_ITE			VARCHAR(11),
	@P_SEQUENCIA_ITE		INT, 
	@P_QTDNEG_ITE  			FLOAT, 
	@P_VLRDESC_ITE			FLOAT,
	@P_VLRUNIT_ITE  		FLOAT,
	@P_VLRTOT_ITE	  		FLOAT,
	@P_BASEICMS_ITE			FLOAT,
	@P_ALIQICMS_ITE			FLOAT,
	@P_VLRICMS_ITE			FLOAT,
	@P_BASEIPI_ITE			FLOAT,
	@P_ALIQIPI_ITE			FLOAT,
	@P_VLRIPI_ITE			FLOAT,
	@P_BASESUBSTIT_ITE		FLOAT,
	@P_VLRSUBST_ITE			FLOAT,
	@P_CODCFO_ITE			INT,
	@P_CODTRIB_ITE			INT,
	@P_CSTIPI_ITE			INT,
	@P_CSOSN_ITE			INT,
	@P_CODUSU_ITE      		INT,      						       
	@P_CODEMP_ITE      		INT,
	@P_CODLOCAL_ITE	  		INT, 
	@P_ATUALEST_ITE		 	INT,	
	@P_REFERENCIA_ITE	 	VARCHAR(10),      
	@P_USOPROD_ITE		  	VARCHAR(1),
	@P_CODVOL_ITE	  		VARCHAR(2),
	@EXISTE					INT

 
BEGIN      

 SELECT @P_NUNOTA = C.NUNOTA 
      , @P_CODTIPOPER = C.CODTIPOPER 
	  , @P_ATUALEST_ITE = CASE WHEN T.ATUALEST = 'B' THEN -1
	                       WHEN T.ATUALEST = 'E' THEN 1
						   ELSE 0 END
   FROM TGFCAB (NOLOCK) C
  INNER JOIN TGFTOP (NOLOCK) T ON C.CODTIPOPER = T.CODTIPOPER AND T.DHALTER = C.DHTIPOPER
  WHERE C.NUMCF = @P_NROUNICOUSE
  

		/*INSERIR ITENS DA NOTA*/
		DECLARE CURSOR_AD_INS_ITE_MOV_USE CURSOR LOCAL FAST_FORWARD FOR   
		SELECT DISTINCT M.CODIGO -- BASE PARA O NUNOTA (AD_NROUNICOUSE NA TGFCAB)
			 , LCA.CODPROD AS CODPROD
			 , LCA.CONTROLE AS CONTROLE
			 --, F.ITEM AS SEQUENCIA
			 , ROW_NUMBER() OVER(ORDER BY F.ITEM ASC) AS SEQUENCIA
			 , F.QTDE AS QTDNEG
			 , F.DESCONTO  AS VLRDESC
			 , ROUND(F.VALORBRUTO  / CASE WHEN F.QTDE = 0 THEN 1 ELSE F.QTDE END,2) AS VLRUNIT
			 , F.VALORBRUTO  AS VLRTOT
			 , F.VLRBCICMS AS BASEICMS
			 , F.ICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F.PFCP ELSE 0 END,0) AS ALIQICMS
			 --, F.ICMS+ISNULL(F.PFCP,0) AS ALIQICMS
			 , F.VLRICMS+ISNULL(CASE WHEN UFS.UF = 'RJ' THEN F.VFCP ELSE 0 END,0) AS VLRICMS
			 --, F.VLRICMS+ISNULL(F.VFCP,0) AS VLRICMS
			 , CASE WHEN F.VLRIPI > 0 THEN F.VLRBCICMS ELSE 0 END AS BASEIPI
			 , F.IPI AS ALIQIPI
			 , F.VLRIPI AS VLRIPI
			 , F.VLRBCST AS BASESUBSTIT
			 , F.VLRST AS VLRSUBST
			 , F.CFOP AS CODCFO
			 , SUBSTRING(F.SITTRIBUTARIAICMS,2,3) AS CODTRIB
			 , F.SITTRIBUTARIAIPI AS CSTIPI
			 , F.CSONSN AS CSOSN
			 , 0 AS CODUSU
			 , L.CODEMP AS CODEMP
			 , 0 AS CODLOCAL
		  FROM AD_TGFLOJA  (NOLOCK)   L 
		 INNER JOIN TSIEMP (NOLOCK) EMP ON L.CODEMP = EMP.CODEMP
		 INNER JOIN TSICID (NOLOCK) CID ON EMP.CODCID = CID.CODCID
		 INNER JOIN TSIUFS (NOLOCK) UFS ON UFS.CODUF = CID.UF
		 INNER JOIN USE_MOVIMENTOESTSAI (NOLOCK)   M ON L.CODLOJA = M.LOJAEMI AND M.STATUSNFE = 3 
		 INNER JOIN USE_ITEMESTSAI (NOLOCK)   F ON M.LOJAEMI = F.MOVIMENTOSAILOJA AND M.CODIGO = F.MOVIMENTOSAI
		 INNER JOIN AD_TGFPROLCA (NOLOCK)   LCA ON F.PRODUTO = LCA.CODIGOPRODUTOUSE
		 WHERE /*L.ATIVO = 'S'  
		   AND*/ L.CODFRANQ = 1 -- LOJAS PROPRIAS
		   AND M.CODIGO = @P_NROUNICOUSE
		   AND M.DATACANCELNFE IS NULL
		   AND M.CHAVENFE IS NOT NULL

  
			OPEN CURSOR_AD_INS_ITE_MOV_USE  
			FETCH NEXT FROM CURSOR_AD_INS_ITE_MOV_USE INTO         @P_NROUNICOUSE,@P_CODPROD_ITE,@P_CONTROLE_ITE,@P_SEQUENCIA_ITE,@P_QTDNEG_ITE,@P_VLRDESC_ITE,@P_VLRUNIT_ITE,  
																   @P_VLRTOT_ITE,@P_BASEICMS_ITE,@P_ALIQICMS_ITE,@P_VLRICMS_ITE,@P_BASEIPI_ITE,@P_ALIQIPI_ITE,@P_VLRIPI_ITE,	
																   @P_BASESUBSTIT_ITE,@P_VLRSUBST_ITE,@P_CODCFO_ITE,@P_CODTRIB_ITE,@P_CSTIPI_ITE,@P_CSOSN_ITE,@P_CODUSU_ITE,			       
										                           @P_CODEMP_ITE,@P_CODLOCAL_ITE	  
			

			WHILE @@FETCH_STATUS = 0  
			BEGIN  
 
		  SELECT @P_REFERENCIA_ITE = REFERENCIA      
			  , @P_USOPROD_ITE = USOPROD 
			  , @P_CODVOL_ITE  = CODVOL	  
		   FROM TGFPRO (NOLOCK)    
		  WHERE CODPROD = @P_CODPROD_ITE  

		SELECT @EXISTE = COUNT(1)
		  FROM TGFITE (NOLOCK) 
		 WHERE NUNOTA = @P_NUNOTA
		   AND SEQUENCIA = @P_SEQUENCIA_ITE

		IF @EXISTE = 0

			BEGIN

				 INSERT INTO TGFITE (NUTAB,NUNOTA,SEQUENCIA,CODEMP,CODPROD,CODLOCALORIG,CONTROLE,      
					  USOPROD,CODCFO,QTDNEG,QTDENTREGUE,QTDCONFERIDA,VLRUNIT,VLRTOT,      
					  VLRCUS,BASEIPI,VLRIPI,ALIQIPI,BASEICMS,ALIQICMS,VLRICMS,      
					  VLRDESC,BASESUBSTIT,VLRSUBST,PENDENTE,CODVOL,CODTRIB,ATUALESTOQUE,      
					  OBSERVACAO,RESERVA,STATUSNOTA,CODEXEC,CODVEND,FATURAR,CODOBSPADRAO,      
					  VLRREPRED,VLRDESCBONIF,PERCDESC,M3,AD_MOT_BONIFICA,AD_DESCMAX,ALIQICMSRED,      
					  CODPARCEXEC,CODUSU,DTALTER,CUSTO,BASESUBSTSEMRED,SOLCOMPRA,CODTRIBISS,      
					  CODCFPS,ALIQISS,QTDFORMULA,ATUALESTTERC,PERCDESCBONIF,TERCEIROS,ENDIMAGEM,      
					  ALTURA,LARGURA,ESPESSURA,CODCAV,CODPROC,QTDPECA,PRECOBASE,      
					  VLRACRESCDESC,VLRRETENCAO,CSTIPI,PERCCOM,VLRCOM,ALTPRECO,QTDFIXADA,      
					  PERCCOMGER,VLRCOMGER,QTDWMS,BASICMMOD,BASICMSTMOD,QTDFAT,BASESTUFDEST,      
					  VLRICMSUFDEST,BASESTANT,GRUPOTRANSG,PRODUTONFE,GTINNFE,GTINTRIBNFE,CODPROMO,      
					  VLRPROMO,VLRLIQPROM,PRECOBASEQTD,RETDATACRITICA,PERCPUREZA,PERCGERMIN,NUPROMOCAO,      
					  PERCDESCPROM,VLRPTOPUREZA,CODANTECIPST,NUMPEDIDO,SEQPEDIDO,CSOSN,STATUSLOTE,      
					  QTDVOL,SERIEINICIAL,SERIEFINAL,DTINICIO,HRINICIO,HRFIM,VLRUNITDOLAR,      
					  PESO,MD5PAF,BASEISS,VLRISS,CODTPA,NUMPEDIDO2,SEQPEDIDO2,      
					  VLRTROCA,VARIACAOFCP,DTFIM,TEMPOGASTO,DESVIOPADRAO,PERCTROCA,PERCDESCDIGITADO,      
					  PERCDESCTGFDES,SEQUENCIAFISCAL,VLRDESCDIGITADO,PERCVC,CODMOTDESONERAICMS,CODETAPA,VARIACAO,      
					  ATUALESTINDIVIDUAL,VLRSTEXTRANOTA,ULOCETPAESTIND,CODLOCALTERC,ORIGPROD,PERCDESCBASE,NRSERIERESERVA,      
					  VLRUNITLOC,VLRICMSANT,BASESUBSTITANT,VLRSUBSTANT,NUMEROOS,CANCELADO,GRUPOFAT,      
					  NUMCONTRATO,IDALIQICMS,VLRUNITMOE,VLRDESCMOE,VLRTOTMOE,CODVOLPARC,CODENQIPI,      
					  CODESPECST,VLRDESCRAT,NUFOP,BASESUBSTITUNITORIG,VLRSUBSTUNITORIG,GERAPRODUCAO,CODAGREGACAO,      
					  INDESCALA,CNPJFABRICANTE,CODBENEFNAUF,BASESTFCPINTANT,PERCSTFCPINTANT,VLRSTFCPINTANT,PERCDESCFORNECEDOR,      
					  ORIGEMBUSCA,PRODUTOPESQUISADO,ALIQSTEXTRANOTA,BASESTEXTRANOTA,QTDTRIBEXPORT,CODPROINFO,ALIQSTFCPSTANT,      
					  VLRVENDAPROMO,VLRREPREDSEMDESC,VLRICMSDIFERIDO,TIPOSEPARACAO,CODDOCARRECAD,NUMDOCARRECAD,BASECALCSTEXTRANOTA,      
					  REDBASEST,MARGLUCRO,PERCREDVLRIPI,IDALIQICMSDIFICMS,TIPENTREGA,      
					  ALIQFETHAB,VLRFETHAB,IDDESCPARCERIA,VLRDESCPARCERIA,IDALIQICMSAT,BASEICMSAT,ALIQICMSAT,      
					  ALIQINTERICMSAT,VLRICMSAT)      
					VALUES (NULL,@P_NUNOTA,@P_SEQUENCIA_ITE,@P_CODEMP_ITE,@P_CODPROD_ITE,@P_CODLOCAL_ITE,@P_CONTROLE_ITE,      
					  @P_USOPROD_ITE,@P_CODCFO_ITE,@P_QTDNEG_ITE,0,0,@P_VLRUNIT_ITE,@P_VLRTOT_ITE,      
					  0,@P_BASEIPI_ITE,@P_VLRIPI_ITE,@P_ALIQIPI_ITE,@P_BASEICMS_ITE,@P_ALIQICMS_ITE,@P_VLRICMS_ITE,      
					  @P_VLRDESC_ITE,@P_BASESUBSTIT_ITE,@P_VLRSUBST_ITE,'N',@P_CODVOL_ITE,@P_CODTRIB_ITE,@P_ATUALEST_ITE,      
					  NULL,'N','L',0,0,'S',NULL,      
					  0,0,0,0,NULL,NULL,0,      
					  0,@P_CODUSU_ITE,GETDATE(),0,0,'N',7,      
					  0,0,NULL,'N',NULL,'N',NULL,      
					  0,0,0,NULL,NULL,NULL,0,      
					  0,0,@P_CSTIPI_ITE,NULL,NULL,NULL,NULL,      
					  NULL,NULL,0,NULL,NULL,NULL,0,      
					  0,0,NULL,@P_REFERENCIA_ITE,@P_REFERENCIA_ITE,@P_REFERENCIA_ITE,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,@P_CSOSN_ITE,'N',      
					  1,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,0,NULL,NULL,0,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,0,0,0,0,NULL,NULL,      
					  NULL,0,NULL,NULL,NULL,'S',NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,0,0,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL,NULL,NULL,NULL,NULL,NULL,      
					  NULL,NULL)      
            END
	
				FETCH NEXT FROM CURSOR_AD_INS_ITE_MOV_USE INTO 	@P_NROUNICOUSE,@P_CODPROD_ITE,@P_CONTROLE_ITE,@P_SEQUENCIA_ITE,@P_QTDNEG_ITE,@P_VLRDESC_ITE,@P_VLRUNIT_ITE,  
														 	    @P_VLRTOT_ITE,@P_BASEICMS_ITE,@P_ALIQICMS_ITE,@P_VLRICMS_ITE,@P_BASEIPI_ITE,@P_ALIQIPI_ITE,@P_VLRIPI_ITE,	
											                    @P_BASESUBSTIT_ITE,@P_VLRSUBST_ITE,@P_CODCFO_ITE,@P_CODTRIB_ITE,@P_CSTIPI_ITE,@P_CSOSN_ITE,@P_CODUSU_ITE,			       
										                        @P_CODEMP_ITE,@P_CODLOCAL_ITE
			END  
  
			CLOSE CURSOR_AD_INS_ITE_MOV_USE  
			DEALLOCATE CURSOR_AD_INS_ITE_MOV_USE  



         

END 
