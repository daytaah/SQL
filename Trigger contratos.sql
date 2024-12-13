USE [SANKHYA_TESTE]
GO

/****** Object:  Trigger [sankhya].[AD_TRG_INC_TGFCAB_DTTERMINOFIN]    Script Date: 13/12/2024 09:20:29 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   TRIGGER  [sankhya].[AD_TRG_INC_TGFCAB_DTTERMINOFIN]
ON [sankhya].[TGFCAB]
FOR INSERT
AS
BEGIN
  
    DECLARE @NUMCONTRATO INT,
            @DTTERMINO   DATE, 
            @DTNEG       DATE,
			@TIPMOV      VARCHAR(1)
      
            
    SELECT @NUMCONTRATO = NUMCONTRATO
         , @DTNEG = DTNEG
		 , @TIPMOV = TIPMOV
    FROM INSERTED
    
	IF @NUMCONTRATO > 0 AND @TIPMOV= 'C'
	BEGIN 
	    SELECT @DTTERMINO = ISNULL(AD_DTTERMINOFIN,'31/12/2999')
          FROM TCSCON 
         WHERE NUMCONTRATO = @NUMCONTRATO

		   IF @DTTERMINO < @DTNEG 
            BEGIN
	    
            EXEC SANKHYA.SNK_ERROR 'Data de Término do financeiro menor que a data de faturamento! AD_TRG_INC_TGFCAB_DTTERMINOFIN'        
            ROLLBACK TRANSACTION
            RETURN
             END

	 END 

	END
GO

ALTER TABLE [sankhya].[TGFCAB] ENABLE TRIGGER [AD_TRG_INC_TGFCAB_DTTERMINOFIN]
GO


