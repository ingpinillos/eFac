USE PCGC
go
print 'eFac 2021-09-20 15:55'
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Set NOCOUNT ON 
-- eFac 
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MTPROCLI' AND COLUMN_NAME='RESP01')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='FC_EFAC')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='FE_PRFJ')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='HR_EFAC')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_CPTO')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_CUFE')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_FCFA')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_NDOC')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_PDOC')
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_TDOC')
If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
if exists(SELECT name FROM sys.all_objects Where name='eFac_Enc') drop view eFac_Enc
if exists(SELECT name FROM sys.all_objects Where name='eFac_FEC') drop Function eFac_FEC
if exists(SELECT name FROM sys.all_objects Where name='eFac_Imp') drop view eFac_Imp
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mail') drop Function eFac_Mail
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mas') drop view eFac_Mas
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mov') drop view eFac_Mov
if exists(SELECT name FROM sys.all_objects Where name='eFac_MTG') drop view eFac_MTG
if exists(SELECT name FROM sys.all_objects Where name='eFac_Resol') drop view eFac_Resol
if exists(SELECT name FROM sys.all_objects Where name='eFac_Rpt') drop view eFac_Rpt
if exists(SELECT name FROM sys.all_objects Where name='eFac_Rsp') drop Function eFac_Rsp
if exists(SELECT name FROM sys.all_objects Where name='eFac_TM') drop Procedure eFac_TM


Declare @nReg as int=0,@nRegDej as int=0,@cNit as Char(20),@cRes as Char(20)
Declare cCResp
Cursor For select nit from ClieRespFiscal group by nit
Open cCResp 
Fetch Next From cCResp 
Into @cNit
While @@FETCH_STATUS = 0
Begin
	select @nReg=Sum(case when codresp in ('O-13','O-15','O-23','O-47','R-99-PN') then 1 else 0 end)
	from ClieRespFiscal where @cNit=nit
	If @nReg=0
		Insert into ClieRespFiscal(nit,codresp)values(@cNit,'R-99-PN')
	Fetch Next From cCResp 
	Into @cNit
End
CLose cCResp 
DEALLOCATE cCResp 
Delete ClieRespFiscal where nit+codresp in (select nit+codresp from ClieRespFiscal where codresp not in ('O-13','O-15','O-23','O-47','R-99-PN'))
Delete MTRESFISCA where codresp not in ('O-13','O-15','O-23','O-47','R-99-PN')
UpDate MTRESFISCA set Nombre='No Responsable'where codresp='R-99-PN'and Nombre<>'No Responsable'
--UpDate mtglobal set valor='2' where campo='NROREDON'and valor<>'2'
Go
if exists(SELECT name FROM sys.all_objects Where name='eFac_Resol') drop view eFac_Resol
Go
Create View eFac_Resol
As
SELECT CODIGOCONS,CONSECINI,CONSECFIN,CONSEREAL,FHAUTORIZ,FVENRESO,IDEFAC_RSL,LLAVEDIAN,NRORESOL,PREFIJDIAN,TESTSETID,TIPODCTO,TIPODCTOFR,
	(Select top 1 isnull(dctomae,'') from tipodcto where origen = 'FAC' and tipodcto=eFac_Resol.tipodcto) DCTOMAE
FROM(SELECT TIPODCTO,TIPODCTOFR,NRORESOL,CONSECINI,CONSECFIN,CONSEREAL,FHAUTORIZ,FVENRESO,IDEFAC_RSL,TESTSETID,PREFIJDIAN,LLAVEDIAN,CODIGOCONS FROM EFAC_RSL
UNION Select TIPODCTO,TIPODCTOFR,NroResol,ConsecIni,ConsecFin,ConsecFin consereal,
	Case When fhautoriz <> '19000101' Then cast(year(fhautoriz) as char(4))+'-'+
		Case When month(fhautoriz) < 10 then '0' else '' end + cast(month(fhautoriz) as varchar(2))+'-'+
		Case When day(fhautoriz) < 10 then '0' else '' end + cast(day(fhautoriz) as varchar(2)) else '1900-01-01' end FhAutoriz,
	Case When FvenReso <> '19000101' Then cast(year(FvenReso) as char(4))+'-'+
		Case When month(FvenReso) < 10 then '0' else '' end + cast(month(FvenReso) as varchar(2))+'-'+
		Case When day(FvenReso) < 10 then '0' else '' end + cast(day(FvenReso) as varchar(2)) else '1900-01-01' end FvenReso,0 IDEFAC_RSL,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR)) FROM MTGLOBAL WHERE CAMPO = 'EFAC16STID') TESTSETID,
	ltrim(rtrim(PREFIJDIAN))PREFIJDIAN,
	ltrim(rtrim(LLAVEDIAN))LLAVEDIAN,
	ltrim(rtrim(CodigoCons))CodigoCons
From Consecut where origen = 'FAC' and len(llavedian) != 0) eFac_Resol
Go

IF OBJECT_ID('dbo.EFAC_TRMAS','U')IS NULL
Begin
	Create TABLE dbo.EFAC_TRMAS(ORIGEN char(3)NOT NULL,TIPODCTO char(2)NOT NULL,NRODCTO char(10)NOT NULL,STADSINCRO bit NULL,
		CONSTRAINT PK_EFAC_TRMAS PRIMARY KEY CLUSTERED(NRODCTO ASC,ORIGEN ASC,TIPODCTO ASC)
	WITH(PAD_INDEX=OFF,STATISTICS_NORECOMPUTE=OFF,IGNORE_DUP_KEY=OFF,ALLOW_ROW_LOCKS=ON,ALLOW_PAGE_LOCKS=ON)ON[PRIMARY])ON[PRIMARY]
	ALTER TABLE dbo.EFAC_TRMAS ADD CONSTRAINT DF__EFAC_TRMAS__ORIGEN DEFAULT('')FOR ORIGEN
	ALTER TABLE dbo.EFAC_TRMAS ADD CONSTRAINT DF__EFAC_TRMAS__TIPODC DEFAULT('')FOR TIPODCTO
	ALTER TABLE dbo.EFAC_TRMAS ADD CONSTRAINT DF__EFAC_TRMAS__NRODCT DEFAULT('')FOR NRODCTO
	ALTER TABLE dbo.EFAC_TRMAS ADD CONSTRAINT DF__EFAC_TRMAS__STADSI DEFAULT((0))FOR STADSINCRO
End
IF OBJECT_ID('dbo.EFAC_RSL','U')IS NULL
Begin
	CREATE TABLE dbo.EFAC_RSL(CODIGOCONS VARCHAR(5)NULL,CONSECINI NUMERIC(10,0)NULL,CONSECFIN NUMERIC(10,0)NULL,CONSEREAL NUMERIC(10,0)NULL,
		FHAUTORIZ VARCHAR(12)NULL,FVENRESO VARCHAR(12)NULL,IDEFAC_RSL INT IDENTITY(1,1)NOT NULL,LLAVEDIAN VARCHAR(100)NULL,NRORESOL CHAR(70)NULL,
		PREFIJDIAN VARCHAR(8)NULL,STADSINCRO bit NULL,TESTSETID VARCHAR(250)NULL,TIPODCTO CHAR(2)NULL,TIPODCTOFR CHAR(2)NULL) ON [PRIMARY]
	insert into efac_rsl(CODIGOCONS,CONSECINI,CONSECFIN,CONSEREAL,FHAUTORIZ,FVENRESO,LLAVEDIAN,NRORESOL,PREFIJDIAN,TESTSETID,TIPODCTO,TIPODCTOFR)
	select CODIGOCONS,CONSECINI,CONSECFIN,0,FHAUTORIZ,FVENRESO,LLAVEDIAN,NRORESOL,PREFIJDIAN,TESTSETID,TIPODCTO,TIPODCTOFR 
		from efac_resol where len(NRORESOL)!=0
End

IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_CPTO')
	ALTER TABLE dbo.EFAC_TRMAS add NC_CPTO char(5)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_CUFE')
	ALTER TABLE dbo.EFAC_TRMAS add NC_CUFE char(250)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_FCFA')
	ALTER TABLE dbo.EFAC_TRMAS add NC_FCFA datetime NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_NDOC')
	ALTER TABLE dbo.EFAC_TRMAS add NC_NDOC char(10)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_TDOC')
	ALTER TABLE dbo.EFAC_TRMAS add NC_TDOC char(2)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='NC_PDOC')
	ALTER TABLE dbo.EFAC_TRMAS add NC_PDOC char(5)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='FC_EFAC')
	ALTER TABLE dbo.EFAC_TRMAS add FC_EFAC datetime NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='FE_PRFJ')
	ALTER TABLE dbo.EFAC_TRMAS add FE_PRFJ char(5)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='FE_CONS')
	ALTER TABLE dbo.EFAC_TRMAS add FE_CONS char(5)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='HR_EFAC')
	ALTER TABLE dbo.EFAC_TRMAS add HR_EFAC char(8)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='FL_EFAC')
	ALTER TABLE dbo.EFAC_TRMAS add FL_EFAC char(60)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='AD_EFAC')
	ALTER TABLE dbo.EFAC_TRMAS add AD_EFAC char(60)NOT NULL DEFAULT''
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='EFAC_TRMAS' AND COLUMN_NAME='TR_EFAC') 
	ALTER TABLE dbo.EFAC_TRMAS add TR_EFAC bit NOT NULL DEFAULT 0

DECLARE @sql NVARCHAR(255)
WHILE EXISTS(SELECT name FROM SYS.OBJECTS WHERE TYPE_DESC LIKE'%CONSTRAINT'AND 
	(NAME LIKE'%TRADEMAS%NC_%'or NAME LIKE'%TRADEMAS%FC_%'or NAME LIKE'%TRADEMAS%FE_%'or NAME LIKE'%TRADEMAS%HR_%'))
BEGIN
	SELECT @sql = 'ALTER TABLE TRADEMAS DROP CONSTRAINT ' + name FROM SYS.OBJECTS
	WHERE TYPE_DESC LIKE '%CONSTRAINT' AND (NAME LIKE '%TRADEMAS%NC_%' or NAME LIKE '%TRADEMAS%FC_%' or NAME LIKE '%TRADEMAS%FE_%' or NAME LIKE '%TRADEMAS%HR_%')
	EXEC sp_executesql @sql
END
WHILE EXISTS (SELECT NAME FROM SYS.OBJECTS WHERE TYPE_DESC LIKE '%CONSTRAINT' AND ((UPPER(NAME) LIKE '%MTPROCLI%RESP01%') OR (UPPER(NAME) LIKE '%MTPROCLI%XEMAIL%')))
BEGIN
	SELECT @sql = 'ALTER TABLE MTPROCLI DROP CONSTRAINT ' + NAME FROM SYS.OBJECTS
	WHERE TYPE_DESC LIKE '%CONSTRAINT' AND ((UPPER(NAME) LIKE '%MTPROCLI%RESP01%') OR (UPPER(NAME) LIKE '%MTPROCLI%XEMAIL%'))
	EXEC SP_EXECUTESQL @sql
END

if not exists(SELECT 1 FROM sys.indexes  WHERE name = 'IDX_EFAC_Trade_ORIGEN' AND object_id = OBJECT_ID('TRADE'))
Create NONCLUSTERED INDEX IDX_EFAC_Trade_ORIGEN ON dbo.Trade (ORIGEN)
INCLUDE (BRUTO,CODMONEDA,D1FECHA1,IVABRUTO,MEUUID,MULTIMON,NIT,NRODCTO,OTRAMON,RTEFTE,TIPODCTO,VRETICA,VRETIVA)

IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_CPTO')
	ALTER TABLE dbo.TRADEMAS drop column NC_CPTO 
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_CUFE')
	ALTER TABLE dbo.TRADEMAS drop column NC_CUFE
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_FCFA')
	ALTER TABLE dbo.TRADEMAS drop column NC_FCFA
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_NDOC')
	ALTER TABLE dbo.TRADEMAS drop column NC_NDOC
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_TDOC')
	ALTER TABLE dbo.TRADEMAS drop column NC_TDOC
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='NC_PDOC')
	ALTER TABLE dbo.TRADEMAS drop column NC_PDOC
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='FC_EFAC')
	ALTER TABLE dbo.TRADEMAS drop column FC_EFAC
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='FE_PRFJ')
	ALTER TABLE dbo.TRADEMAS drop column FE_PRFJ
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TRADEMAS' AND COLUMN_NAME='HR_EFAC')
	ALTER TABLE dbo.TRADEMAS drop column HR_EFAC
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MTPROCLI' AND COLUMN_NAME='RESP01')
	ALTER TABLE dbo.MTPROCLI drop column RESP01
IF not EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='MTPROCLI' AND COLUMN_NAME='EMAILFEC')
	ALTER TABLE dbo.MTPROCLI add EMAILFEC char(250)NOT NULL DEFAULT ''
If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
	DELETE CONTROL_OFIMAENTERPRISE..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) IN('NC_CPTO','NC_CUFE','NC_FCFA','NC_NDOC','NC_TDOC','NC_PDOC','FC_EFAC','FE_PRFJ','HR_EFAC')
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMAENTERPRISE..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'TRADEMAS')
Else
	DELETE CONTROL_OFIMA2015_01..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) IN('NC_CPTO','NC_CUFE','NC_FCFA','NC_NDOC','NC_TDOC','NC_PDOC','FC_EFAC','FE_PRFJ','HR_EFAC')
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMA2015_01..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'TRADEMAS')
If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
	DELETE CONTROL_OFIMAENTERPRISE..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) = 'RESP01'
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMAENTERPRISE..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'MTPROCLI')
Else
	DELETE CONTROL_OFIMA2015_01..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) = 'RESP01'
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMA2015_01..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'MTPROCLI')

If exists(SELECT name FROM master..sysdatabases WHERE (name = 'CONTROL_OFIMAENTERPRISE'))
	DELETE CONTROL_OFIMAENTERPRISE..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) = 'XEMAILEFAC'
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMAENTERPRISE..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'MTPROCLI')
Else
	DELETE CONTROL_OFIMA2015_01..CAMPOOFIMA WHERE UPPER(NOMBRECAMPO) = 'XEMAILEFAC'
		AND IDTABLA IN(SELECT IDTABLA  FROM CONTROL_OFIMA2015_01..TABLAOFIMA WHERE UPPER(NOMBRETABLA) = 'MTPROCLI')
/*
USE \\server\OFIMATICA\OFIMAENTERPRISE\ATLASCS\TECNICO\DICCITEC.DBF 
DELETE FOR INLIST(UPPER(FIELD_NAME),'NC_CPTO','NC_CUFE','NC_FCFA','NC_NDOC','NC_TDOC','NC_PDOC','FC_EFAC','FE_PRFJ','HR_EFAC').AND.UPPER(BDATOS)='TRADEMAS'
DELETE FOR UPPER(FIELD_NAME)='RESP01'.AND.UPPER(BDATOS)='MTPROCLI'
*/
/*
select distinct mediopag from trade where mediopag != '0'
UpDate trade set mediopag='0' where mediopag=' '
UpDate trade set mediopag='45' where mediopag='05'
delete mtmedpag where mediopag='05'
select * from mtmedpag
insert into mtmedpag
(concepto,efectivo,mediopag,descripcio)
values ('05',1,'10','Efectivo'),
('05',0,'20','Cheque'),
('05',0,'42','Consiganción bancaria'),
('05',0,'45','Transferencia Crédito Bancario'),
('05',0,'48','Tarjeta Crédito'),
('05',0,'49','Tarjeta Débito')
*/
IF OBJECT_ID('dbo.EFAC_CONCEPNC','U')IS NULL
Begin
	Create TABLE dbo.EFAC_CONCEPNC(CODIGO char(2)NULL,NOMBRE char(100)NULL)ON [PRIMARY]
	insert into dbo.EFAC_CONCEPNC
	Values
	(1,'Devolución de parte de los bienes; no aceptación de partes del servicio'),
	(2,'Anulación de factura electrónica'),
	(3,'Rebaja o descuento parcial o total'),
	(4,'Ajuste por precio'),
	(5,'Otros')
End
Go
if exists(SELECT name FROM sys.all_objects Where name='eFac_FEC') drop Function eFac_FEC
Go
Create Function eFac_FEC(@Id as Bit,@pFecha Date)
Returns VarChar(Max)
Begin
	Declare @wMes as VarChar(Max)='',@wRet as VarChar(Max)=''
	If @Id=0 --Ingles
	Begin
		If month(@pFecha) = 1
			Set @wMes='january'
		Else If month(@pFecha) = 2
			Set @wMes='february'
		Else If month(@pFecha) = 3
			Set @wMes='march'
		Else If month(@pFecha) = 4
			Set @wMes='april'
		Else If month(@pFecha) = 5
			Set @wMes='may'
		Else If month(@pFecha) = 6
			Set @wMes='june'
		Else If month(@pFecha) = 7
			Set @wMes='july'
		Else If month(@pFecha) = 8
			Set @wMes='august'
		Else If month(@pFecha) = 9
			Set @wMes='september'
		Else If month(@pFecha) = 10
			Set @wMes='october'
		Else If month(@pFecha) = 11
			Set @wMes='november'
		Else Set @wMes='december'
		If day(@pFecha)<10
			Set @wRet=@wRet+'0'
		Set @wRet=@wMes+' '+@wRet+Cast(day(@pFecha)as varchar(2))+' '+Cast(year(@pFecha)as varchar(4))
	End
	Else
	Begin
		If month(@pFecha) = 1
			Set @wMes='enero'
		Else If month(@pFecha) = 2
			Set @wMes='febrero'
		Else If month(@pFecha) = 3
			Set @wMes='marzo'
		Else If month(@pFecha) = 4
			Set @wMes='abril'
		Else If month(@pFecha) = 5
			Set @wMes='mayo'
		Else If month(@pFecha) = 6
			Set @wMes='junio'
		Else If month(@pFecha) = 7
			Set @wMes='julio'
		Else If month(@pFecha) = 8
			Set @wMes='agosto'
		Else If month(@pFecha) = 9
			Set @wMes='septiembre'
		Else If month(@pFecha) = 10
			Set @wMes='octubre'
		Else If month(@pFecha) = 11
			Set @wMes='noviembre'
		Else Set @wMes='diciembre'
		If day(@pFecha)<10
			Set @wRet='0'
		Set @wRet=@wRet+Cast(day(@pFecha)as varchar(2))+' '+@wMes+' '+Cast(year(@pFecha)as varchar(4))
	End
	Return @wRet
End
GO
IF OBJECT_ID('dbo.EFAC_CONCEPND','U')IS NULL
Begin
	Create TABLE dbo.EFAC_CONCEPND(CODIGO char(2)NULL,NOMBRE char(100)NULL)ON [PRIMARY]
	insert into dbo.EFAC_CONCEPND
	Values
	(1 ,'Intereses'),(2 ,'Gastos por cobrar'),(3 ,'Cambio del valor'),(4 ,'Otros ')
End
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_MTG') drop view eFac_MTG
Go
Create VIEW dbo.eFac_MTG 
AS 
Select (SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC00EMP')EFAC00,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC01ALS')EFAC01,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC02SRV')EFAC02,
	(SELECT TOP 1 (isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC03CLV')EFAC03,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC04NIT')EFAC04,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC05NOM')EFAC05,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC06DIR')EFAC06,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC07TEL')EFAC07,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC08MAT')EFAC08,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC09AEF')EFAC09,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC10CP')EFAC10,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC11RES')EFAC11,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC12EML')EFAC12,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC13EST')EFAC13,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC142242')EFAC14,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC15VP')EFAC15,
	(SELECT TOP 1 (isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC16STID')EFAC16,
	(SELECT TOP 1 (isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC17IDEN')EFAC17,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC18SW')EFAC18,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC19PIN')EFAC19,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC20FAC')EFAC20,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC21CLV')EFAC21,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC22TDC')EFAC22,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC23FDG')EFAC23,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC24CMUN')EFAC24,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC25NMUN')EFAC25,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC26CPAI')EFAC26,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC27NPAI')EFAC27,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC28CDPT')EFAC28,
	(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC29NDPT')EFAC29,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC30IDI')EFAC30,
	(SELECT TOP 1 lower(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC31AT1_8')EFAC31,
	'<Generado por la solución de software propio '
	+(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC18SW')
	+' de: '+(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='EFAC05NOM')
	+' NIT: '+(SELECT TOP 1 upper(isnull(LTRIM(RTRIM(VALOR)),''))FROM MTGLOBAL WHERE CAMPO='NITCIA')+'>' eFacImp

GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mas') drop view eFac_Mas
Go
Create VIEW dbo.eFac_Mas 
AS 
	SELECT TR.Origen,TR.TipoDcto,TR.NroDcto,
	isnull(TM.NC_CPTO,'')NC_CPTO,
	isnull(TM.NC_CUFE,'')NC_CUFE,
	cast(isnull(TM.NC_FCFA,'')as date)NC_FCFA,
	isnull(TM.NC_NDOC,'')NC_NDOC,
	isnull(TM.NC_TDOC,'')NC_TDOC,
	isnull(TM.NC_PDOC,'')NC_PDOC,
	CONVERT(datetime,CONVERT(varchar,isnull(TM.FC_EFAC,'1900-01-01'),23)+' '+isnull(TM.HR_EFAC,'00:00:00'),20)FC_EFAC,
	isnull(C.nombre,'')NOMBRE,
	ltrim(rtrim(isnull(TM.FE_PRFJ,'')))PREFIJO,
	TR.MEUUID,
	dbo.eFac_FEC(1,tr.fecha)txtFECHA,
	dbo.eFac_FEC(1,case when tr.fecha1<=tr.fecha then tr.fecha+1 else tr.fecha1 end)txtFECHA1,
	dbo.eFac_FEC(0,tr.fecha)xtxtFECHA,
	dbo.eFac_FEC(1,case when tr.fecha1<=tr.fecha then tr.fecha+1 else tr.fecha1 end)xtxtFECHA1,
	Case when tr.fecha1-tr.fecha>1 then 'CREDITO '+ltrim(rtrim(cast(tr.fecha1-tr.fecha as integer)))+' DIAS'
	else 'CREDITO 1 DIA' end TIP_NEG,
	isnull(TM.FE_CONS,'') CONSECUT,
	isnull(TM.FL_EFAC,'')FL_EFAC,
	isnull(TM.AD_EFAC,'')AD_EFAC,
	case when substring(isnull(TM.AD_EFAC,''),1,2)='ad'then'ar'+substring(isnull(TM.AD_EFAC,''),3,58) else isnull(TM.AD_EFAC,'') end AR_EFAC,
	isnull(TM.TR_EFAC,0)TR_EFAC
	FROM TRADE TR
		inner join TIPODCTO TD on TR.Origen=TD.Origen And TR.TipoDcto=TD.TipoDcto
		left join EFAC_TRMAS TM on TR.Origen=TM.Origen And TR.TipoDcto=TM.TipoDcto And TR.NroDcto=TM.NroDcto
		left join eFAC_ConcepNC C on codigo=NC_CPTO 
	Where TR.Origen='FAC' And TD.DctoMae in('FA','FR','NC','ND')
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mov') drop view eFac_Mov
Go
Create VIEW dbo.eFac_Mov 
AS 
Select origen,tipodcto,nrodcto,paranc,cantidad,nombre,um,
	abs(round(total/CANTIDAD,decimales))valor,
	total,
	fecha,
	producto,
	nota,
	lote,
	poriva,
	abs(round(total*(PORIVA/100),decimales))TOTIVA,
	porret,
	abs(round(total*(PorRet/100),decimales))TOTRET,
	prteica,
	abs(round(total*(prteica/100),decimales))TOTICA,
	prteiva,
	abs(round(total*(PORIVA/100)*(prteiva/100),decimales))TOTRIV,
	descuento,
	valor_Ref,
	idmvtrade,
	decimales, 
	TotBas=Case Total when 0 then Cantidad * Valor_Ref else Total end
From (SELECT M.ORIGEN,
	M.TIPODCTO,
	M.NRODCTO,
	MTMERCIA.referprov PARANC,
	abs((M.CANTIDAD))cantidad,
	case when len(m.NOTA)!=0 then m.NOTA else m.NOMBRE end NOMBRE,
	CASE WHEN LEN(UNIDINT)=0 THEN UNDVENTA ELSE UNIDINT END um,
	round(abs(round(((M.CANTIDAD*M.VLRVENTA)-(M.CANTIDAD*M.VLRVENTA*(M.DESCUENTO/100))
		-(((M.CANTIDAD*M.VLRVENTA)-(M.CANTIDAD*M.VLRVENTA*(M.DESCUENTO/100)))*(T.DSCTOCOM/100))),decimales)),decimales)total,
	cast(t.FECHA as date)FECHA,
	PRODUCTO,
	rtrim(ltrim(m.bodega))+'-'+rtrim(ltrim(m.NOTA))NOTA,
	(OrdenNro)Lote,
	M.IVA PORIVA,
	case when DCTOMAE IN('FA','FR')then 1 else 0 end*M.PORETE PorRet,
	case when DCTOMAE IN('FA','FR')then 1 else 0 end*m.porica/10 prteica,
	case when DCTOMAE IN('FA','FR')then 1 else 0 end*(case when t.pretiva=0 then m.preteniva else t.pretiva end) prteiva,
	case when t.DSCTOCOM=0 then M.Descuento else t.DSCTOCOM end descuento,
	isnull(mp.PRECIO,0)*0.55 valor_Ref,
	(IDMVTRADE)IDMVTRADE,
	decimales
FROM MVTRADE M 
INNER JOIN TRADE T ON T.ORIGEN=M.ORIGEN and T.TIPODCTO=M.TIPODCTO and T.NRODCTO=M.NRODCTO
INNER JOIN TIPODCTO D ON T.ORIGEN=D.ORIGEN and T.TIPODCTO=D.TIPODCTO
INNER JOIN MTMERCIA ON CODIGO = PRODUCTO 
INNER JOIN MTUNIDAD ON UNDVENTA = UNIDAD 
INNER JOIN MtProcli ON T.NIT = MTPROCLI.NIT 
LEFT JOIN MvPrecio MP ON M.PRODUCTO = MP.CODPRODUC and MP.CODPRECIO = MTPROCLI.CODPRECIO 
WHERE M.ORIGEN = 'FAC' AND DCTOMAE IN('FA','FR','NC','ND') AND M.CANTIDAD != 0) MV
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Imp') drop view eFac_Imp
Go
Create VIEW dbo.eFac_Imp 
AS 
SELECT ORIGEN,TIPODCTO,NRODCTO,CODIGO,NOMBRE,PORIMP,SUM(BASIMP)BASIMP,SUM(round(PORIMP*BASIMP/100,decimales))VALIMP,
	case when CODIGO='01' then AVG(c01) else
	case when CODIGO='05' then AVG(c05) else 
	case when CODIGO='06' then AVG(c06) else
	case when CODIGO='07' then AVG(c07) else 0 end end end end TOTIMP
FROM(
	SELECT ORIGEN,TIPODCTO,NRODCTO,'01'CODIGO,'IVA'NOMBRE,PORIVA PORIMP,TotBas BASIMP,decimales--,TOTIVA VALIMP
	FROM eFac_Mov
UNION ALL
	SELECT ORIGEN,TIPODCTO,NRODCTO,'05'CODIGO,'ReteIVA'NOMBRE,prteiva PORIMP,round(PORIVA*TOTAL/100,decimales)BASIMP,decimales--,TOTRIV VALIMP
	FROM eFac_Mov
UNION ALL
	SELECT ORIGEN,TIPODCTO,NRODCTO,'06'CODIGO,'ReteFuente'NOMBRE,PorRet PORIMP,TOTAL BASIMP,decimales--,TOTRET VALIMP
	FROM eFac_Mov
UNION ALL
	SELECT ORIGEN,TIPODCTO,NRODCTO,'07'CODIGO,'ReteICA'NOMBRE,prteica PORIMP,TOTAL BASIMP,decimales--,TOTICA VALIMP
	FROM eFac_Mov)MV inner join 
	(SELECT ORIGEN o,TIPODCTO t,NRODCTO n,--sum(TOTIVA)c01,sum(TOTRIV)c05,sum(TOTRET)c06,sum(TOTICA)c07 
		SUM(round(PORIVA*TOTAL/100,decimales))c01,
		SUM(round(prteiva*TOTIVA/100,decimales))c05,
		SUM(round(PorRet*TOTAL/100,decimales))c06,
		SUM(round(prteica*TOTAL/100,decimales))c07
	FROM eFac_Mov GROUP BY ORIGEN,TIPODCTO,NRODCTO)TR 
	on o=origen and t=tipodcto and n=nrodcto 
where (codigo = '01' or (codigo<>'01' and (PORIMP*BASIMP)<>0))
GROUP BY ORIGEN,TIPODCTO,NRODCTO,CODIGO,NOMBRE,PORIMP
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Mail') drop Function eFac_Mail
Go
Create Function dbo.eFac_Mail(@pNit varchar(max))
Returns varchar(max)
AS
BEGIN
 	DECLARE @string VARCHAR(MAX)='',@wTEMP VARCHAR(MAX)='',@pMails VARCHAR(MAX)=@pNit
	DECLARE @i integer=1,@j integer=1

	Set @wTEMP = ''
	If len(@pNit) > 4
	Begin
		Declare cCEmails Cursor For 
		SELECT ltrim(rtrim(EMAILFEC)) Email
		FROM MTPROCLI WHERE NIT = @pNit
		Open cCEmails 
		Fetch Next From cCEmails 
		Into @string
		While @@FETCH_STATUS = 0
		Begin
			Set @wTEMP = ltrim(rtrim(@wTEMP)) + ltrim(rtrim(@string)) + ','
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Fetch Next From cCEmails 
			Into @string
		End
		CLose cCEmails 
		DEALLOCATE cCEmails
		if len(@wTEMP) < 5
			Set @wTEMP = @pMails
		Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
		Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
		Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')

		if len(@wTEMP) < 5 or not @wTEMP like('%@%.%')
		Begin 
			Set @wTEMP=''
			Declare cCEmails Cursor For 
			SELECT ltrim(rtrim(EMAIL)) Email
			FROM MTPROCLI WHERE NIT = @pNit
			Open cCEmails 
			Fetch Next From cCEmails 
			Into @string
			While @@FETCH_STATUS = 0
			Begin
				Set @wTEMP = ltrim(rtrim(@wTEMP)) + ltrim(rtrim(@string)) + ','
				Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
				Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
				Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
				Fetch Next From cCEmails 
				Into @string
			End
			CLose cCEmails 
			DEALLOCATE cCEmails
		End
		SET @string = @wTEMP

		declare @TTable TABLE (i integer,j integer,email varchar(max))
		Set @j = CHARINDEX(',',@string,@i)
 		while @j <> 0
		Begin
			set @wTEMP = substring(@string,@i,@j-@i)
			Insert into @TTable 
			select @i,@j,@wTEMP
			Set @i = @j+1
			Set @j = CHARINDEX(',',@string,@i)
		End
		Declare cCEmails Cursor For 
		Select distinct email from @TTable
		SET @wTEMP = ''
		Open cCEmails 
		Fetch Next From cCEmails 
		Into @string
		While @@FETCH_STATUS = 0
		Begin
			Set @wTEMP = ltrim(rtrim(@wTEMP)) + ',' + ltrim(rtrim(@string))
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Set @wTEMP = replace(replace(replace(@wTEMP,',,',','),' ',','),';',',')
			Fetch Next From cCEmails 
			Into @string
		End
		CLose cCEmails 
		DEALLOCATE cCEmails
		SET @string = REPLACE(@wTEMP,';',',')
		If substring(@string,1,1) = ','
			SET @wTEMP = substring(@string,2,len(@string))
	End
	return @wTemp
end
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Rsp') drop Function eFac_Rsp
Go
Create Function dbo.eFac_Rsp(@pParam varchar(max))
Returns varchar(max)
AS
BEGIN
 	DECLARE @string VARCHAR(MAX)='',@wEXTRAE varchar(max)
	DECLARE @wTEMP VARCHAR(MAX)=''
	DECLARE @WLARGO INTEGER=LEN(@pPARAM),@i integer=1
	DECLARE @WBIT varchar (max)=''
	DECLARE @WVALIDAS VARCHAR(MAX)='O-06;O-07;O-08;O-09;O-13;O-14;O-15;O-16;O-17;O-19;O-22;O-23;O-32;O-33;O-34;O-36;O-37;O-38;O-39;O-47;O-48;O-49;O-52;O-99;R-99-PN'
	If GETDATE()>'20200731'
		SET @WVALIDAS='O-13;O-15;O-23;O-47;R-99-PN'

	Set @wTEMP = ''
	If len(@wTEMP) < 1
	Begin
		Declare cCResp
		Cursor For Select isnull(RESP_FISCAL,'') RESP_FISCAL From v_ClienteRespFiscal where CLIENTE = @pParam  
		--Union Select xrespon RESP_FISCAL From mtprocli where xrespon<>'' and NIT=@pParam
		ORDER BY RESP_FISCAL
		-- Abrir El Cursor
		Open cCResp 
		-- Inicializar los primeros registos para procesar
		Fetch Next From cCResp 
		Into @string
		-- Realizar el Ciclo de la temporal	
		While @@FETCH_STATUS = 0
		Begin
			Set @wTEMP = ltrim(rtrim(@wTEMP)) + ';' + ltrim(rtrim(@string)) 
			Fetch Next From cCResp 
			Into @string
		End
		CLose cCResp 
		DEALLOCATE cCResp 
 	End
	Set @wTEMP=ltrim(rtrim(@wTEMP))
	If len(@wTEMP) = 0 
		Set @wTEMP=@pParam
	SET @string = REPLACE(REPLACE(@wTEMP,' ',';'),',',';')+';'
	SET @wTEMP = ''
 	SET @WLARGO = LEN(@STRING)
 	while @i <= @wlargo
	Begin
	SET @wEXTRAE = SUBSTRING(@STRING,@I,1)
		  IF @wEXTRAE = ';'
		  Begin
				IF SUBSTRING(@wbit,1,1) in('0','1','2','3','4','5','6','7','8','9') and len(@wbit) = 1 Set @WBIT='O-0'+@WBIT
				IF SUBSTRING(@wbit,1,1) in('0','1','2','3','4','5','6','7','8','9') and len(@wbit) = 2 Set @WBIT='O-'+@WBIT
				IF SUBSTRING(@wbit,1,1) != 'O' and SUBSTRING(@wbit,1,1) != 'R' Set @WBIT='O-'+@WBIT
				IF @WVALIDAS LIKE ('%'+@WBIT+'%')
				Begin
					  if len(@wTEMP)>0 SET @wTEMP=rtrim(ltrim(@wTEMP))+';'
					  SET @wTEMP=rtrim(ltrim(@wTEMP))+@WBIT
				End  
				SET @WBIT=''
		  End
		  Else
				Set @WBIT=@WBIT+@wEXTRAE
		set @i=@i+1
	End
	Set @wTEMP = replace(@wTEMP,'O-;','')
	IF substring(@wTEMP,len(@wTEMP)-2,len(@wTEMP)) = ';O-' SET @wTEMP = substring(@wTEMP,1,len(@wTEMP)-3)
	IF len(@wTEMP) < 4 SET @wTEMP=''	
	return @wTemp
end
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Enc') drop view eFac_Enc
Go
Create VIEW dbo.eFac_Enc 
AS 
Select ORIGEN,TIPODCTO,NRODCTO,PREFIJO,(BRUTO+IVABRUTO-DESCUENTO)APAGAR,APEL,BRUTO,CDDPTO,CIUADQ,CODCIU,CODPAIADQ,CODPOSTAL,CONCEPTO_NOTA,CONSECUT,
	ISNULL(PREFIJO+LTRIM(RTRIM(NRODCTO))+(cast(FECHA as varchar)+HORA)+cast(cast(round(BRUTO,decimales)as numeric(17,2))as varchar(20))
	+'01'+cast(cast(round(IVABRUTO,decimales)as numeric(17,2))as varchar(20))+'04'+'0.00'+'03'+'0.00'
	+cast(cast(round(BRUTO+IVABRUTO-DESCUENTO,decimales)as numeric(17,2))as varchar(20))--ValPag
	+case when charindex('-',NitOFE)>1 then substring(NitOFE,1,charindex('-',NitOFE)-1)else NitOFE end --NitOFE 
	+CASE WHEN PAIS=169 THEN case when charindex('-',xNITADQ)>1 then substring(xNITADQ,1,charindex('-',xNITADQ)-1)else xNITADQ end
	else xNITADQ end+LLAVEDIAN+EFACEST,'') as CUFE,
	CUFEFAC_NOTA,DCTOMAE,DECIMALES,DESCUENTO,DIRADQ,DIROFE,
	'<cbc:'+Case when TIPADQ!='2'then'Company'else''end+'ID'+
	Case when TIPDOC='31'and charindex('-',xNITADQ)>1 then' schemeID="'+substring(xNITADQ,charindex('-',xNITADQ)+1,1)+'"'ELSE''END+
	' schemeName="'+LTRIM(RTRIM(tipdoc))+'"'+
	' schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+
	CASE WHEN PAIS = 169 THEN 
	case when charindex('-',xNITADQ) > 1 then substring(xNITADQ,1,charindex('-',xNITADQ)-1) else xNITADQ end 
	else xNITADQ end+'</cbc:'+Case when TIPADQ!='2'then'Company'else''end+'ID>'DOCADQ,
	'<cbc:CompanyID'+' schemeID="'+CASE WHEN charindex('-',NITOFE) > 1 then substring(NITOFE,charindex('-',NITOFE)+1,1) ELSE '' END+ 
	'" schemeName="31"'+' schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+
	case when charindex('-',NITOFE) > 1 then substring(NITOFE,1,charindex('-',NITOFE)-1) else NITOFE end+'</cbc:CompanyID>'DOCOFE,
	EFAC2242,EFACAEF,EFACCP,EFACEST,EFACFAC,EFACIDEN,EFACPIN,EFACRES,EFACSW,EFACTSTSETID,EFACVP,EMAIL,EMLADQ,EMLOFE,
	EXTERIOR,FACTURA_NOTA,FC_EFAC,FECFAC_NOTA,FECHA,FECHA_OC,FECHA_VENCE,FINPOR,FINVAL,FOR_PAG,HORA,IDEFAC_RSL,IDSWPT,INCOTERMS,
	INCTRMSNM,IVABRUTO,LLAVEDIAN,MEUUID,MONEDA,MULTIMON,NC_CPTO,NC_CUFE,NC_FCFA,NC_NDOC,NC_TDOC,NIT,NIT_SUC,
	CASE WHEN PAIS=169 THEN case when charindex('-',xNITADQ)>1 then substring(xNITADQ,1,charindex('-',xNITADQ)-1)else xNITADQ end else xNITADQ end NITADQ,
	case when charindex('-',NitOFE)>1 then substring(NitOFE,1,charindex('-',NitOFE)-1)else NitOFE end NITOBL,NITOFE,NOMBREDEPTO NMDPTO,NOM,NOM1,NOM2,
	nom+' - '+ CASE WHEN PAIS=169 THEN case when charindex('-',xNITADQ)>1 then substring(xNITADQ,1,charindex('-',xNITADQ)-1)else xNITADQ end
	else xNITADQ end NOMADQ,NOMBREDEPTO,NOMOFE,NOMPAIADQ,NOTA,NUMER_OC,ORDEN,OTRAMON,PAIADQ,PAIS,PREFIJO_NOTA,
	'https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey=' as QR,REGADQ,REGOFE,RESPON,RETENCIONES,RTEFTE,RTEICA,RTEIVA,SINIVA,
	(BRUTO+IVABRUTO)SUBTOTAL,TASA,TCAR,TELADQ,TELOFE,TIPADQ,TIPDOC,
	/*
	20 Nota Crédito que referencia una factura electrónica. 
	22 Nota Crédito sin referencia a facturas*. 
	23 Nota Crédito para facturación electrónica V1 (Decreto 2242). 
	*/
	case when FECFAC_Nota>=cast(EFAC2242 as date)and FECFAC_Nota<cast(EFACVP as date) then '23' else 
	case when FECFAC_Nota>=cast(EFACVP as date)then '20' else '22' end end TIPFAC_NOTA,
	TIPODOC_NOTA,(BRUTO-DESCUENTO+IVABRUTO) TOTAL,TR_EFAC,
	'<cbc:CompanyID '+
	Case when TIPDOC='31'and charindex('-',xNITADQ)>1 then'schemeID="'+substring(xNITADQ,charindex('-',xNITADQ)+1,1)+'"'ELSE''END+
	' schemeName="'+LTRIM(RTRIM(tipdoc))+'"'+
	' schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">'+
	CASE WHEN PAIS = 169 THEN case when charindex('-',xNITADQ) > 1 then substring(xNITADQ,1,charindex('-',xNITADQ)-1) else xNITADQ end 
	else xNITADQ end+'</cbc:CompanyID>'XDOCADQ,XNITADQ, Base
from (
SELECT 
	T.ORIGEN,
	T.TIPODCTO,
	T.NRODCTO,
	T.OTRAMON,
	T.MULTIMON,
	T.ORDEN Numer_OC,
	cast(T.FECHANIF as date)Fecha_OC,
	C.PAIS,
	C.EXTERIOR,
	SUBSTRING(T.TRANSPORTA,1,3)INCOTERMS,
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='CFR' THEN 'COSTO Y FLETE' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='CIF' THEN 'COSTO,FLETE Y SEGURO' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='CIP' THEN 'TRANSPORTE Y SEGURO PAGADOS HASTA' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='CPT' THEN 'TRANSPORTE PAGADO HASTA' ELSE 
--	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='DAP' THEN 'ENTREGADO EN UN LUGAR' ELSE 
--	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='DAT' THEN 'ENTREGADO EN TERMINAL' ELSE 
--	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='DDP' THEN 'ENTREGADO CON PAGO DE DERECHOS' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='EXW' THEN 'EN FÁBRICA' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='FAS' THEN 'FRANCO AL COSTADO DEL BUQUE' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='FCA' THEN 'FRANCO TRANSPORTISTA' ELSE 
	CASE WHEN SUBSTRING(T.TRANSPORTA,1,3)='FOB' THEN 'FRANCO A BORDO' ELSE SUBSTRING(T.TRANSPORTA,6,50)END END END END END END END END INCTRMSNM,
/*
Cód Significado 
CFR,COSTO Y FLETE 
CIF,COSTO,FLETE Y SEGURO 
CIP,TRANSPORTE Y SEGURO PAGADOS HASTA 
CPT,TRANSPORTE PAGADO HASTA 
DAP,ENTREGADO EN UN LUGAR 
DAT,ENTREGADO EN TERMINAL 
DDP,ENTREGADO CON PAGO DE DERECHOS 
EXW,EN FÁBRICA 
FAS,FRANCO AL COSTADO DEL BUQUE 
FCA,FRANCO TRANSPORTISTA 
FOB,FRANCO A BORDO 
*/
	CASE WHEN T.OTRAMON='S' THEN 'USD' ELSE CASE WHEN T.MULTIMON=1 THEN T.CODMONEDA ELSE 'COP' END END MONEDA,
	cast(T.FECHA as date)FECHA,
	--cast(getdate()as date)FECHA,
	cast(T.FECHA1 as date)FECHA_VENCE,
	T.HORA+'-05:00' HORA,
	ltrim(rtrim(T.NOTA))NOTA,
	ltrim(rtrim(X.NOMBRE))CIUADQ,
	ltrim(rtrim(C.DIRECCION))DIRADQ,
	ltrim(rtrim(cast(CASE WHEN LEN(codalterno)=0 THEN T.nit ELSE C.codalterno END as varchar(20))))xNITADQ,
	ltrim(rtrim(cast(CASE WHEN LEN(codalterno)=0 THEN T.nit ELSE C.codalterno END as varchar(20))))NIT,
	ltrim(rtrim(cast(CASE WHEN LEN(codalterno)!=0 THEN T.nit ELSE C.codalterno END as varchar(20))))NIT_SUC,
	ltrim(rtrim(C.NOMBRE))NOM,
	SUBSTRING(P.ISO_3166_1,1,2)PAIADQ,
	SUBSTRING(P.ISO_3166_1,1,2)CODPAIADQ,
	ltrim(rtrim(P.ISO_3166_1))NOMPAIADQ,
	CASE WHEN C.REGSIMP=0 THEN '2' ELSE '0' END REGADQ,--0 Simplificado/2 Común
	C.TEL1 AS TELADQ,
	CASE WHEN T.OTRAMON='S' THEN T.TCAMBIO ELSE CASE WHEN T.MULTIMON=1 THEN T.TCAMBIO * T.TCAMBIOMM ELSE 0 END END TASA,
	CASE WHEN C.PERSONANJ=1 THEN '2' ELSE CASE WHEN C.PAIS!=169 THEN '1' ELSE '1' END END TIPADQ,--1 Jurídica/2 Natural/3 Gran Contribuyente/4 Otros R-00-PN
	isnull(ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)),BRUTO)BRUTO,
	isnull(ABS((SELECT AVG(TOTIMP) from eFac_Imp I where I.CODIGO='01'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),IVABRUTO)IVABRUTO,
	isnull(ABS((SELECT AVG(TOTIMP) from eFac_Imp I where I.CODIGO='06'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),RTEFTE)RTEFTE,
	isnull(ABS((SELECT AVG(TOTIMP) from eFac_Imp I where I.CODIGO='07'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),VRETICA)RTEICA,
	isnull(ABS((SELECT AVG(TOTIMP) from eFac_Imp I where I.CODIGO='05'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),VRETIVA)RTEIVA,
	isnull(ABS(CASE WHEN T.OTRAMON='S' THEN T.XSINIVA ELSE CASE WHEN T.MULTIMON=1 THEN T.ZSINIVA ELSE T.SINIVA END END),SINIVA)SINIVA,
	ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)*(CASE WHEN NITOFE='860020246-0'THEN 0 ELSE D1FECHA1 END)/100) DESCUENTO,
	/*
	isnull((ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)
	+(SELECT SUM(TOTIMP)from eFac_Imp I where I.CODIGO='01'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO))
	- ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)*(D1FECHA1)/100)),
	BRUTO+IVABRUTO)TOTAL,
	abs(BRUTO-DESCUENTO+IVABRUTO)APAGAR,
	isnull(ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)
	- ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)*(T.D1FECHA1/100))
	+(SELECT SUM(TOTIVA)from eFac_Imp I where I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),BRUTO+IVABRUTO)APAGAR,
	isnull(ABS((SELECT SUM(TOTAL)from eFac_mov m where M.ORIGEN=T.ORIGEN and M.TIPODCTO=T.TIPODCTO and M.NRODCTO=T.NRODCTO)
	+(SELECT SUM(TOTIMP)from eFac_Imp I where I.CODIGO='01'and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),0)SUBTOTAL,
	abs(BRUTO-DESCUENTO+IVABRUTO)SUBTOTAL,
	*/
	isnull(ABS((SELECT SUM(TOTIMP)from eFac_Imp I where I.CODIGO in('05','06','07') and I.ORIGEN=T.ORIGEN and I.TIPODCTO=T.TIPODCTO and I.NRODCTO=T.NRODCTO)),0)RETENCIONES,
	T.TIPOCAR as TCAR,
	T.ORDEN,
	Case when t.fecha1-t.fecha>0 then ltrim(rtrim(cast(t.fecha1-t.fecha as integer)))+' DIAS'
	else 'ANTICIPADO' end FOR_PAG,
	CASE when len(ltrim(rtrim(c.NOMBRE1))+ltrim(rtrim(C.NOMBRE2))+ltrim(rtrim(C.APELLIDO1))+ltrim(rtrim(C.APELLIDO2)))=0 
		then ltrim(rtrim(C.NOMBRE))else c.NOMBRE1 end NOM1,
	C.NOMBRE2 NOM2,
	C.APELLIDO1+C.APELLIDO2 APEL,
	C.clase tipdoc,
	eFac_Var.*,
	X.CODCIUDAD CodCiu,
	upper(isnull((SELECT TOP 1 NOMBRE FROM MTDEPTO WHERE CODDEPTO=SUBSTRING(X.CODCIUDAD,1,2)),''))NOMBREDEPTO,
	upper(isnull((SELECT TOP 1 CODDEPTO FROM MTDEPTO WHERE CODDEPTO=SUBSTRING(X.CODCIUDAD,1,2)),''))CdDpto,
	C.CODPOSTAL CODPOSTAL,
	dbo.eFac_Mail(c.email)EMLADQ,
	dbo.eFac_Mail(c.nit)email,
--	dbo.eFac_Rsp(C.RESP01)Respon,
	dbo.eFac_Rsp(C.NIT)Respon,
	ISNULL(TM.NC_TDOC,'')NC_TDOC,
	CASE WHEN ISNULL(TM.NC_PDOC,'')<> '' THEN NC_PDOC ELSE '' END+ISNULL(TM.NC_NDOC,'')NC_NDOC,
	ISNULL(TM.NC_CPTO,'')NC_CPTO,
	ISNULL(TM.NC_CUFE,'')NC_CUFE,
	ISNULL(TM.NC_FCFA,'')NC_FCFA,
	ISNULL(TM.TR_eFAC,0)TR_eFAC,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then ISNULL(TM.NC_CPTO,'')else '' end CONCEPTO_Nota,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then ISNULL(TM.NC_NDOC,'')else '' end FACTURA_Nota,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then ISNULL(TM.NC_TDOC,'')else '' end TIPODOC_Nota,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then ISNULL(TM.NC_PDOC,'')else '' end PREFIJO_Nota,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then 
	(select top 1 cast(fecha as date)from trade where origen='FAC' and tipodcto=ISNULL(TM.NC_TDOC,'') and nrodcto=ISNULL(TM.NC_NDOC,''))
	else '' end FECFAC_Nota,
	CASE WHEN TIPODCTO.DCTOMAE IN ('NC','ND')then ISNULL(TM.NC_CUFE,'')else '' end CUFEFAC_Nota,
	cast(FC_EFAC as datetime)FC_EFAC,
	T.MEUUID,
	T.D1FECHA1 FINPOR,
	T.DESCFINANC finval,
	PREFIJO,LLAVEDIAN,TIPODCTO.DCTOMAE,CONSECUT,decimales,IDEFAC_RSL,
	Base=(Select sum(TotBas) From eFac_Mov M Where T.ORIGEN=M.ORIGEN and T.TIPODCTO=M.TIPODCTO and T.NRODCTO=M.NRODCTO)
	--@@VALOR BASE DE LA FACTURA@@
FROM TRADE T 
	LEFT JOIN eFac_Mas TM ON T.ORIGEN=TM.ORIGEN and T.TIPODCTO=TM.TIPODCTO and T.NRODCTO=TM.NRODCTO
	LEFT JOIN eFac_Resol R on R.CodigoCons=TM.CONSECUT AND (T.NRODCTO BETWEEN consecini and consereal OR R.DCTOMAE IN('NC','ND'))
	INNER JOIN MTPROCLI C ON T.NIT=C.NIT 
	INNER JOIN MTPAISES P ON P.CODIGO=C.PAIS
	inner join CIUDAD X on X.CODCIUDAD=C.CIUDAD
	INNER JOIN TIPODCTO ON T.TIPODCTO=TIPODCTO.TIPODCTO AND TIPODCTO.ORIGEN='FAC' AND TIPODCTO.DCTOMAE IN('FA','FR','NC','ND'),
	(Select (SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='NITCIA')NITOFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC05NOM')NOMOFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC06DIR')DIROFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC07TEL')TELOFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC08MAT')REGOFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC09AEF')EFACAEF,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC10CP')EFACCP,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC11RES')EFACRES,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC12EML')EMLOFE,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC13EST')EFACEST,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC142242')EFAC2242,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC15VP')EFACVP,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC16STID')EFACTSTSETID,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC17IDEN')EFACIDEN,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC17IDEN')IDSWPT,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC18SW')EFACSW,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC19PIN')EFACPIN,
	(SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC20FAC')EFACFAC) eFac_Var
WHERE T.ORIGEN='FAC')xx
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_TM') drop Procedure eFac_TM
Go
Create Procedure eFac_TM
(@pCampo varchar(max),@pTipDcto varchar(max),@NroDcto varchar(max),@pParam varchar(max),@pParam1 datetime)
As
Begin
	Set NOCOUNT ON 
	declare @wfl as Varchar(60)='',@wvl as Int=0
	If (select count(*)cnt from EFAC_TRMAS where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto)=0 
		and (select count(*)cnt from trade where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto)=1
		Insert into EFAC_TRMAS (Origen,TipoDcto,NroDcto,Fc_EFAC)Values ('FAC',@pTipDcto,@NroDcto,CAST('1900-01-01' as datetime))
	If @pCampo='FECHA' and @pParam1>cast((SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC142242') as date)
	Begin
		UpDate EFAC_TRMAS set FC_EFAC=CAST(@pParam1 as date)
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
		UpDate EFAC_TRMAS set HR_EFAC=SUBSTRING(convert(VARCHAR(MAX),@pParam1,120),12,8)
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	End
	If @pCampo='CUFE' 
	Begin
		If len(@pParam)=96 or len(@pParam)=40
		Begin
			UpDate TRADE Set MEUUID=@pParam 
			where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto and len(rtrim(MEUUID))=0 
		End
		If len(@pParam)!=96 and len(@pParam)!=40
			UpDate TRADE set MEUUID='' 
			where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto 
	End
	If @pCampo='CONSE' 
		UpDate EFAC_TRMAS set FE_CONS=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto	
	If @pCampo='PRFJ' 
		UpDate EFAC_TRMAS set FE_PRFJ=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	If @pCampo='NC_CPTO'
		UpDate EFAC_TRMAS set NC_CPTO=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	If @pCampo='NC_NDOC'
		UpDate EFAC_TRMAS set NC_NDOC=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	If @pCampo='NC_TDOC'
		UpDate EFAC_TRMAS set NC_TDOC=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	If @pCampo='NC_PDOC'
		UpDate EFAC_TRMAS set NC_PDOC=@pParam
		where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto
	If @pCampo='NC_CUFE'
		UpDate EFAC_TRMAS set NC_CUFE=@pParam
		Where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto	
	If @pCampo='TR_EFAC'
	Begin
		UpDate eFac_TRMas set TR_EFAC=case when len(rtrim(MEUUID))<>0 and FC_EFAC<>'19000101'then 1 else 0 end 
		From eFac_TRMas, TRADE 
		Where eFac_TRMas.Origen='FAC' and eFac_TRMas.TipoDcto=@pTipDcto and eFac_TRMas.NroDcto=@NroDcto and TRADE.Origen=eFac_TRMas.Origen 
			and TRADE.TipoDcto=eFac_TRMas.TipoDcto and TRADE.NroDcto=eFac_TRMas.NroDcto 

		Select @wvl=isnull(ideFac_RSL,0)From eFac_Enc Where Origen='FAC' and eFac_Enc.TipoDcto=@pTipDcto and NroDcto=@NroDcto
		If @wvl=0
			insert into efac_rsl(CODIGOCONS,CONSECINI,CONSECFIN,CONSEREAL,FHAUTORIZ,FVENRESO,LLAVEDIAN,NRORESOL,PREFIJDIAN,TESTSETID,TIPODCTO,TIPODCTOFR)
			select CODIGOCONS,CONSECINI,CONSECFIN,Cast(@NroDcto As Int),FHAUTORIZ,FVENRESO,LLAVEDIAN,NRORESOL,PREFIJDIAN,TESTSETID,TIPODCTO,TIPODCTOFR from efac_resol 
			where len(NRORESOL)!=0 and LLAVEDIAN+PREFIJDIAN not in(Select LLAVEDIAN+PREFIJDIAN From efac_rsl)
		Else
			UpDate eFac_RSL Set ConseReal=Cast(@NroDcto As Int)where @wvl=ideFac_RSL and ConseReal<Cast(@NroDcto As Int)
	End
	If @pCampo='FL_EFAC'
	Begin
		Set @wfl='Error'
		IF substring(@pParam,1,2)='NC'
			select @wfl=cast(isnull(max(cast(substring(fl_efac,16,10) as int)),0)+1 as varchar(10))
			from efac_mas 
			inner join tipodcto on efac_mas.tipodcto=tipodcto.tipodcto and efac_mas.origen=tipodcto.origen 
			where efac_mas.Origen='FAC' and dctomae in('NC') and year(@pParam1) = cast(2000+substring(fl_efac,16,2) as int) and efac_mas.TipoDcto=@pTipDcto
		else IF substring(@pParam,1,2)='ND'
			select @wfl=cast(isnull(max(cast(substring(fl_efac,16,10) as int)),0)+1 as varchar(10))
			from efac_mas 
			inner join tipodcto on efac_mas.tipodcto=tipodcto.tipodcto and efac_mas.origen=tipodcto.origen 
			where efac_mas.Origen='FAC' and dctomae in('ND') and year(@pParam1) = cast(2000+substring(fl_efac,16,2) as int) and efac_mas.TipoDcto=@pTipDcto
		else IF substring(@pParam,1,2)in('FA','FR')
			select @wfl=cast(isnull(max(cast(substring(fl_efac,16,10) as int)),0)+1 as varchar(10))
			from efac_mas 
			inner join tipodcto on efac_mas.tipodcto=tipodcto.tipodcto and efac_mas.origen=tipodcto.origen 
			where efac_mas.Origen='FAC' and dctomae in('FA','FR') and year(@pParam1) = cast(2000+substring(fl_efac,16,2) as int) and efac_mas.TipoDcto=@pTipDcto

		if @wfl<>'Error'
		Begin
			if len(@wfl)<8 Set @wfl=substring(cast(year(@pParam1) as varchar(4)),3,2)+replicate('0',8-len(@wfl))+@wfl
			IF substring(@pParam,1,2)='NC'
				Set @wfl='nc0'+substring(@pParam,3,9)+'000'+@wfl
			else IF substring(@pParam,1,2)='ND'
				Set @wfl='nd0'+substring(@pParam,3,9)+'000'+@wfl
			else IF substring(@pParam,1,2)in('FA','FR')
				Set @wfl='fv0'+substring(@pParam,3,9)+'000'+@wfl

			UpDate EFAC_TRMAS set fl_efac=@wfl where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto and len(fl_efac) = 0
			
			Set @wfl='Error'
			select @wfl=cast(isnull(max(cast(substring(ad_efac,16,10) as int)),0)+1 as varchar(10))
			from efac_mas 
			inner join tipodcto on efac_mas.tipodcto=tipodcto.tipodcto and efac_mas.origen=tipodcto.origen 
			where efac_mas.Origen='FAC' and dctomae in('FA','FR','NC','ND') and year(@pParam1) = cast(2000+substring(ad_efac,16,2) as int)
			
			if len(@wfl)<8 Set @wfl=substring(cast(year(@pParam1) as varchar(4)),3,2)+replicate('0',8-len(@wfl))+@wfl
			Set @wfl='ad0'+substring(@pParam,3,9)+'000'+@wfl
			UpDate EFAC_TRMAS set ad_efac=@wfl where Origen='FAC' and TipoDcto=@pTipDcto and NroDcto=@NroDcto and len(ad_efac) = 0
		End
	End
	--NC_FCFA
	Begin
		UpDate efac_trmas set nc_fcfa=fecha from efac_trmas
			inner join trade on efac_trmas.origen=trade.origen and efac_trmas.nc_tdoc=trade.tipodcto and efac_trmas.nc_ndoc=trade.nrodcto
			inner join tipodcto on efac_trmas.tipodcto=tipodcto.tipodcto and efac_trmas.origen=tipodcto.origen 
		where efac_trmas.Origen='FAC' and dctomae in('NC','ND') and nc_fcfa='19000101' and efac_trmas.TipoDcto=@pTipDcto and efac_trmas.NroDcto=@NroDcto
	End
End
GO
if exists(SELECT name FROM sys.all_objects Where name='eFac_Rpt') drop view eFac_Rpt
Go
Create VIEW dbo.eFac_Rpt
AS 
	Select TR.TipoDcto,TM.FE_PRFJ Prefijo,TR.NroDcto Factura,Fecha,
		ltrim(rtrim(cast(CASE WHEN LEN(codalterno)=0 THEN TR.nit ELSE CL.codalterno END as varchar(20)))) NITAdq,
		nombre NomAdq,Bruto,Descuento,IVABruto,RteFTE,TR.VRETICA RteICA,TR.VRETENIVA RteIVA, 
		BRUTO+IVABRUTO-RTEFTE-DESCUENTO-VRETICA-VRETENIVA Total,
		CASE WHEN TR.OTRAMON='S' THEN 'USD' ELSE CASE WHEN TR.MULTIMON=1 THEN TR.CODMONEDA ELSE 'COP' END END Moneda,
		isnull(MEUUID,'')CUFE_CUDE,isnull(FC_EFAC,cast('1900-01-01' as datetime))FEC,TR_EFAC Transmitida
	From trade TR 
		inner join mtprocli cl on TR.nit=cl.nit 	
		inner join TIPODCTO ON TR.TIPODCTO=TIPODCTO.TIPODCTO AND TR.ORIGEN=TIPODCTO.ORIGEN
		left join efac_trmas TM on TR.origen=tm.origen and TR.tipodcto=TM.tipodcto and TR.nrodcto=TM.nrodcto
	Where fecha>=cast((SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC15VP') as date) AND TR.ORIGEN='FAC' AND DCTOMAE IN('FA','FR','NC','ND')
--	Select TipoDcto,Prefijo,NroDcto Factura,Fecha,XNITADQ NITAdq,NOM NomAdq,Bruto,IVABruto,RteFTE,RteICA,RteIVA,Total,Moneda,
--		isnull(MEUUID,'')CUFE_CUDE,isnull(FC_EFAC,cast('1900-01-01' as datetime))FEC,TR_EFAC Transmitida
--	From dbo.eFac_Enc Where fecha>=cast((SELECT TOP 1 LTRIM(RTRIM(VALOR))FROM MTGLOBAL WHERE CAMPO='EFAC15VP') as date)
GO
