** PCGC eFac_V2
PROCEDURE eFac
PARAMETERS gEmpresa,pTipoDcto,pNroDcto
	PUBLIC wCUFE,wCUDE,wQRFILE,wNumFactNc,wConceptoNC,wDOCS,QRFILE,WDIR,wtxtFECHA,wtxtFECHA1,wxFECHA,wxFECHA1
	PUBLIC pEmp,pNIT,pSRV,pFec,pTDM,pPFE,pCFE,pCer,wTESTSETID,wTipoSalida,wLink,eFacImp,eFacZip,pPwd,pPWD,pCCo,pRZS
	*PUBLIC mNroResol,mfhautoriz,mFvenReso,mConsecIni,mConsecFin
	wborrador=.t.
	gEmpresa=ALLTRIM(gEmpresa)
	pTipoDcto=ALLTRIM(pTipoDcto)
	pNroDcto=ALLTRIM(pNroDcto)
	wVer='eFac 2021-09-02 10:50'
	WAIT WINDOW NOWAIT wVer+' - '+'INI'
	DO eFac_INI
	IF (BETWEEN(curEncabezado.fecha,ctod(mfhautoriz),CTOD(mFvenReso)) AND INLIST(pTDM,"FA","FR")) or INLIST(pTDM,"NC","ND")
		IF pemp!="XX" AND curEncabezado.fecha>=pFec AND pCFE!="X"
			WAIT WINDOW NOWAIT wVer+' - '+'INI->GENERAR-'+pemp+'-'+pPFE+pNroDcto
			DO eFac_TM
			IF USED("eFac_Valid")
				SELECT eFac_Valid
				USE
			ENDIF
			SELECT 0 
			IF SQLEXEC(gConexEmp,"Select * from eFac_Enc where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto","eFac_Valid") < 0
				WAIT WINDOW NOWAIT wVer+' - '+"ERROR DE CONEXION 2"+pemp
			ENDIF
			SELECT eFac_Valid
			GOTO TOP
			IF EMPTY(ALLTRIM(CODPOSTAL)) OR EMPTY(ALLTRIM(EMAIL)) OR EMPTY(ALLTRIM(NOMBREDEPTO)) OR EMPTY(ALLTRIM(CIUADQ)) OR EMPTY(ALLTRIM(EMLADQ)) OR PAIS='0'
				wborrador=.t.
				wTXT=''
				IF EMPTY(ALLTRIM(CODPOSTAL))
					wTXT=wTXT+'CODPOSTAL '
				ENDIF
				IF EMPTY(ALLTRIM(EMAIL)) 
					wTXT=wTXT+'EMAIL '
				ENDIF
				IF EMPTY(ALLTRIM(NOMBREDEPTO)) 
					wTXT=wTXT+'NOMBREDEPTO '
				ENDIF
				IF EMPTY(ALLTRIM(CIUADQ)) 
					wTXT=wTXT+'CIUADQ '
				ENDIF
				IF EMPTY(ALLTRIM(EMLADQ)) 
					wTXT=wTXT+'EMAILFEC '
				ENDIF
				IF PAIS='0'
					wTXT=wTXT+'PAIS'
				ENDIF
				MESSAGEBOX("El cliente no tiene la informacion completa:"+CHR(13)+wTXT,16,"Facturación electrónica")
				SELECT eFac_VALID
				USE
				SELECT CURMVTO
				GO TOP
			ELSE
				SELECT eFac_VALID
				USE
				SELECT CURMVTO
				GO TOP
				DO eFac_TM
				IF INLIST(pTDM,"NC","ND")
					wCUDE=GEN_CUFE()
					wDOCS=''
					wCUFE=ALLTRIM(TRADEMAS.NC_CUFE)
					CUFE=wCUDE
					wNumFactNc=""
					wConceptoNC=""
					IF pTDM="NC"
						warchivo="\\"+pSRV+"\eFac\OBJ\eFacxNC" 
						wDOCS='Nota Credito'
					ENDIF
					IF pTDM="ND"
						warchivo="\\"+pSRV+"\eFac\OBJ\eFacxND" 
						wDOCS='Nota Debito'
					ENDIF
					DO FORM &warchivo WITH pNroDcto
					DO eFac_TM
					wCUDE=GEN_CUFE()
					wDOCS=wDOCS+' por '+ALLTRIM(IIF(ISNULL(TRADEMAS.nombre),'',ALLTRIM(TRADEMAS.nombre)))
					wDOCS=wDOCS+IIF(UPPER(TRADEMAS.nombre)='OTROS',' otros conceptos','')
					wDOCS=wDOCS+' No.:'+ALLTRIM(TRADEMAS.nc_PDoc)+ALLTRIM(TRADEMAS.nc_NDoc)+' de '+TRADEMAS.nc_fcfa
					wCUFE=ALLTRIM(TRADEMAS.NC_CUFE)
					CUFE=wCUDE
				ELSE
					wCUDE=""
					wDOCS=""
					wCUFE=GEN_CUFE()
					CUFE=wCUFE
				ENDIF
				wLink='https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey='+CUFE
				IF LEN(ALLTRIM(TRADEMAS.MEUUID))=0 
					IF MESSAGEBOX('Desea transmitir a la DIAN:'+CHR(13)+pPFE+pNroDcto,4+32,'Facturación electrónica')=6
						lcArchivo="\\"+pSRV+"\eFac\"+gempresa+"\out\"+fnombre()+"*.*"
						DELETE FILE &lcArchivo
						wQRFILE=GEN_QR()
						Select curMvto
						Go Top
						DO GEN_eFac
						DO eFac_TM
						Select curEncabezado
						Go Top
						Select curMvto
						Go Top
						DO eFac_PDF
						IF SUBSTR(PEMP,2,1)='0'
							DO eFac_Mail WITH .f.
						ELSE
							DO eFac_Mail WITH .T.
						ENDIF
					ELSE
						wborrador=.t.
					ENDIF
				ELSE
					wQRFILE=GEN_QR()
					CUFE=wCUFE
					wborrador=.f.
					Select curEncabezado
					Go Top
					Select curMvto
					Go Top
					DO eFac_PDF
					IF MESSAGEBOX('Desea enviar el correo electrónico al cliente',4+32+256,'Facturación electrónica')=6
						DO eFac_Mail WITH .T.
					ELSE
						IF SUBSTR(PEMP,2,1)='0'
							DO eFac_Mail WITH .f.
						ENDIF
					ENDIF
				ENDIF 
			ENDIF 
			IF "VFPENCRYPTION.FLL"$SET("Library")
				warchivo="'\\"+pSRV+"\eFac\Obj\vfpencryption.fll'"
				RELEASE LIBRARY &warchivo
			ENDIF
			IF "FOXBARCODEQR.FXP"$SET("Procedure")
				warchivo="'\\"+pSRV+"\eFac\Obj\FoxBarcodeQR.fxp'"
				RELEASE PROCEDURE &warchivo
			ENDIF
			IF "CDO2000.FXP"$SET("Procedure")
				warchivo="'\\"+pSRV+"\eFac\Obj\CDO2000.FXP'"
				RELEASE PROCEDURE &warchivo
			ENDIF
			WAIT WINDOW NOWAIT wVer+' - '+'FIN->GENERAR-'+pemp+'-'+pPFE+pNroDcto
		ENDIF
	ENDIF
	Select curMvto
	Go Top
RETURN 
** FIN
****

FUNCTION GEN_eFac
WAIT WINDOW NOWAIT wVer+' - '+'INI->CREAR-'+pemp+'-'+pPFE+pNroDcto
DO CASE
	CASE INLIST(pTDM,'FA','FR')
		wtipodcto='FACTURA'
	CASE INLIST(pTDM,"ND")
		wtipodcto='NOTA DÉBITO'
	CASE INLIST(pTDM,"NC")
		wtipodcto='NOTA CRÉDITO'
ENDCASE 
SET DELETED ON
SET CONFIRM OFF
SET SAFETY OFF
SET TALK OFF
xml_pre=gen_xml()
xml_emi=''
IF FILE(xml_pre)
	xml_sig=firma_xml(xml_pre)
	IF FILE(xml_sig)
		xml_emi=emitir_xml(xml_sig)
		IF SUBSTR(pemp,2,1)='0'
			MESSAGEBOX('LA '+wtipodcto+' ELECTRÓNICA '+fnombre()+' se genero por favor consultela en la DIAN '+chr(13)+xml_emi,64,'eFac')
		ELSE
			xml_emi="\\"+pSRV+"\eFac\"+gempresa+"\in\"
			xml_emi=xml_emi+ALLTRIM(fnombre())+"_emi.XML"
			IF FILE(xml_emi)
				MESSAGEBOX('LA '+wtipodcto+' ELECTRÓNICA '+fnombre()+',HA SIDO AUTORIZADA',64,'eFac')
			ELSE
				MESSAGEBOX('LA '+wtipodcto+' ELECTRÓNICA '+fnombre()+' NO EMITIDA '+xml_emi,16,'eFac')
				xml_emi=''
			ENDIF
		ENDIF
	ELSE
		MESSAGEBOX('LA '+wtipodcto+' ELECTRÓNICA '+fnombre()+' NO FIRMADA',64,'eFac')
	ENDIF
ELSE
	MESSAGEBOX('LA '+wtipodcto+' ELECTRÓNICA '+fnombre()+' YA SE ENCUENTRA AUTORIZADA',64,'eFac')
ENDIF
IF USED('TEMPQR')
	SELECT tempqr
	USE
ENDIF
IF USED('QR')
	SELECT qr
	USE
ENDIF
WAIT WINDOW NOWAIT wVer+' - '+'FIN->CREAR-'+pemp+'-'+pPFE+pNroDcto
RETURN xml_emi
ENDFUNC
**
FUNCTION GEN_XML
WAIT WINDOW NOWAIT wVer+' - '+'INI->XML-'+pemp+'-'+pPFE+pNroDcto
PUBLIC w_token_sesionid,w_token_fechavencimiento,wpuntodeventaid,wtipodecomprobanteid,wnrocbte,w_empresa
IF SYS(101)<>'SCREEN'
	SET DEVICE TO SCREEN
ENDIF
SET MEMOWIDTH TO 8192
wrep=""
wpuntodeventaid="10000"
wcadena=250
w_empresa='0'
SELECT 0
IF USED('Parametros')
	SELECT parametros
	USE
ENDIF
warchivo="\\"+pSRV+"\eFac\Obj\eFac0"+pemp+".dll"
USE &warchivo ALIAS parametros
fxml="\\"+pSRV+"\eFac\"+gEmpresa+"\in\"+fnombre()
SELECT 0
IF USED('Enc')
	SELECT enc
	USE
ENDIF
IF SQLEXEC(gConexEmp,"Select * from eFac_Enc where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto","Enc") < 0
	WAIT WINDOW NOWAIT wVer+' - '+'ERROR DE CONEXION 2'+pemp
ENDIF
SELECT enc
GOTO TOP
IF EOF()
	RETURN 0
ENDIF
SELECT 0
IF USED('Mov')
	SELECT mov
	USE
ENDIF
IF SQLEXEC(gConexEmp,"Select *,ROW_NUMBER() OVER (ORDER BY idmvtrade) AS Linea from eFac_Mov where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto","Mov") < 0
	WAIT WINDOW NOWAIT wVer+' - '+'ERROR DE CONEXION 3'+pemp
ENDIF
SELECT mov
COUNT TO wcnt
GOTO TOP
SELECT 0
IF USED('Imp')
	SELECT imp
	USE
ENDIF
IF SQLEXEC(gConexEmp,"Select * from eFac_IMP where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto order by codigo","Imp") < 0
	WAIT WINDOW NOWAIT wVer+' - '+'ERROR DE CONEXION 4.1'+pemp
ENDIF
SELECT imp
COUNT TO wcnt_imp
GOTO TOP
wcod_imp = codigo
SELECT 0
IF USED('Base')
	SELECT base
	USE
ENDIF
wfactura=pPFE+pnrodcto
wtd=pPFE+ALLTRIM(pnrodcto)
warchivo="\\"+pSRV+"\eFac\Obj\eFac000"
IF INLIST(pTDM,'FA','FR')
	IF SUBSTR(pemp,2,1)='0'
		warchivo=warchivo+"SP.dll"
	ELSE
		IF enc.Pais='169'
			warchivo=warchivo+"FN.dll"
		ELSE
			warchivo=warchivo+"FE.dll"
		ENDIF
	ENDIF
	wpuntodeventaid="10001"
	wtipodecomprobanteid="1"
ELSE
	IF INLIST(pTDM,"NC")
		IF enc.Pais='169'
			warchivo=warchivo+"CN.dll"
		ELSE
			warchivo=warchivo+"CE.dll"
		ENDIF
		wtipodecomprobanteid="4"
	ENDIF
	IF INLIST(pTDM,"ND")
		IF enc.Pais='169'
			warchivo=warchivo+"DN.dll"
		ELSE
			warchivo=warchivo+"DE.dll"
		ENDIF
		wtipodecomprobanteid="5"
	ENDIF
ENDIF
USE &warchivo ALIAS base
INDEX ON (sec * 1000)+ord TO SYS(3)
GOTO TOP
IF FILE(fxml+".xml")
	WAIT WINDOW NOWAIT wVer+' - '+'Ya Existe: '+fxml
	fxml=''
ELSE
	fxml=fxml+'_PRE.xml'
	SET CONSOLE OFF
	SET PRINTER TO FILE &fxml
	SET PRINTER ON
	f=0
	wtotal=0
	wunit=wtotal
	SCAN
		IF enc.moneda<>'USD' AND INLIST(pTDM,"NC","ND") AND sec=50
			f=f
		ELSE
			wini=ini
			IF '"COP"'$wini
				DO CASE
					CASE enc.moneda='USD'
						wini=STRTRAN(ini,'COP','USD')
					CASE enc.moneda='GBP'
						wini=STRTRAN(ini,'COP','GBP')
					CASE enc.moneda='EUR'
						wini=STRTRAN(ini,'COP','EUR')
					CASE enc.moneda='BS'
						wini=STRTRAN(ini,'COP','VEF')
					CASE enc.moneda='COP'
						wini=ini
					OTHERWISE
						wini=STRTRAN(ini,'COP','0')
				ENDCASE
			ENDIF
			IF 'cac:TaxTotal>'$wini AND sec=60 AND wcod_imp<>'01'
				wini=STRTRAN(wini,'cac:TaxTotal','cac:WithholdingTaxTotal')
			ENDIF
			IF '@@' $ dat
				SELECT parametros
				GOTO TOP
				LOCATE FOR parametros.dat=base.dat
				wdat=ALLTRIM(parametros.val)
				IF base.dat='@@VALOR TOTAL LINEA@@'
					IF mov.total<>0 AND mov.cantidad<>0
						wtotal=mov.total / mov.cantidad
						wunit=wtotal
					ELSE
						wunit=wtotal
						wtotal=wtotal * mov.cantidad
					ENDIF
				ENDIF
				DO CASE
					CASE base.dat='@@NUMERO DE LINEAS@@'
						wdat=STR(wcnt)
					CASE base.dat='@@CUFE@@'
						wdat=wCUFE
					CASE base.dat='@@CUDE@@'
						wdat=wCUDE
					CASE base.dat='@@QR Code@@'
						wdat=ALLTRIM(enc.qr)+IIF(wCUDE='',wCUFE,wCUDE)
					CASE base.dat='@@VALOR EN LETRAS EXP@@'
						wdat=eFac_enlet(enc.total,enc.moneda)
					CASE base.dat='@@VALOR EN LETRAS@@'
						wdat=xeFac_enlet(enc.total,enc.moneda)
					CASE base.dat='@@CANTIDAD(NETO)@@'
						wdat=ALLTRIM(mov.um)+'">'+ALLTRIM(STR(ABS(mov.cantidad),10,0))
					CASE base.dat='@@CODIGO SEGURIDAD DE SOFTWARE@@'
						wdat=wdat+ALLTRIM(enc.IDSWPT)
						wdat=wdat+ALLTRIM(enc.eFacPIN)
						wdat=wdat+ALLTRIM(enc.PREFIJO)
						wdat=wdat+ALLTRIM(enc.nrodcto)
						wdat=LOWER(STRCONV(hash(wdat,3),15))
					OTHERWISE
						IF 'enc.' $ wdat OR 'mov.' $ wdat OR 'imp.' $ wdat
							DO CASE
								CASE TYPE(ALLTRIM(parametros.val))='C'
									wdat=ALLTRIM(&wdat)
								CASE TYPE(ALLTRIM(parametros.val))='M'
									wdat=ALLTRIM(&wdat)
								CASE TYPE(ALLTRIM(parametros.val))='D'
									wdat=ALLTRIM(DTOC(&wdat))
								CASE TYPE(ALLTRIM(parametros.val))='N'
									IF INLIST((base.sec*1000)+base.ord,20020)
										wdat=STR(ROUND(ABS(&wdat),0),17,0)
									ELSE
										IF enc.moneda='COP'
											IF 'PORCENTAJE'$base.dat
												wdat=ALLTRIM(STR(ROUND(ABS(&wdat),4),17,4))
												IF SUBSTR(wdat,LEN(wdat),1)='0'
													wdat=SUBSTR(wdat,1,LEN(wdat)-1)
												ENDIF
												IF SUBSTR(wdat,LEN(wdat),1)='0'
													wdat=SUBSTR(wdat,1,LEN(wdat)-1)
												ENDIF
											ELSE
												wdat=STR(ROUND(ABS(&wdat),2),17,2)
											ENDIF
										ELSE
											IF 'PORCENTAJE'$base.dat
												wdat=STR(ROUND(ABS(&wdat),2),17,2)
											ELSE
												wdat=STR(ROUND(ABS(&wdat),6),17,6)
											ENDIF
										ENDIF
									ENDIF
									*wdat=STR(ROUND(ABS(&wdat),wdec),17,wdec)
								OTHERWISE
									wdat=" "
							ENDCASE
						ELSE 
							IF 'var.' $ wdat 
								wdat=SUBSTR(wdat,5,100)
								wdat=ALLTRIM(&wdat)
							ENDIF
						ENDIF
				ENDCASE
			ELSE
				wdat=ALLTRIM(dat)
			ENDIF
		ENDIF
		SELECT base
		wini=ALLTRIM(utf8encode(wini))
		IF f=0
			?? ALLTRIM(wini)
		ELSE
			? ALLTRIM(wini)
		ENDIF
		wdat=ALLTRIM(utf8encode(wdat))
		?? ALLTRIM(wdat)
		wfin=ALLTRIM(utf8encode(fin))
		?? ALLTRIM(wfin)
		*MANEJO DE VARIAS TARIFAS DE IMPUESTOS
		SELECT base
		IF sec=60 AND ord=70
			SELECT imp
			SKIP
			IF wcod_imp=codigo AND .NOT. EOF()
				SELECT base
				LOCATE FOR sec=60 AND ord=15
				SKIP -1
			ELSE
				SKIP -1
			ENDIF
		ENDIF
		SELECT base
		IF sec=60 AND ord=75
			SELECT imp
			SKIP
			IF wcod_imp!=codigo AND .NOT. EOF()
				SELECT base
				LOCATE FOR sec=60 AND ord=5
				SKIP -1
			ELSE
				SKIP -1
			ENDIF 
		ENDIF
		SELECT imp
		wcod_imp=imp.codigo
		*MANEJO DE CAMPOS PARA PERSONA NATURAL
		SELECT base
		IF Sec=35 AND ord=15 AND enc.tipadq<>'2'
			LOCATE FOR sec=35 AND ord=30
		ENDIF
		IF Sec=35 AND ord=345 AND enc.tipadq<>'2'
			LOCATE FOR sec=35 AND ord=395
		ENDIF
		*MANEJO DE PRECIO DE REFERENCIA PARA OBSEQUIOS
		IF Sec=40 AND ord=25 AND enc.finval=0 AND enc.moneda='COP'
			LOCATE FOR sec=45 AND ord=70
		ENDIF
		IF sec=90 AND ord=21 AND mov.total<>0 
			LOCATE FOR sec=90 AND ord=28
		ENDIF
		IF sec=90 AND ord=70 AND mov.totriv=0 AND INLIST(pTDM,"FA","FR")
			LOCATE FOR sec=90 AND ord=90
		ENDIF
		IF sec=90 AND ord=90 AND mov.totret=0 AND INLIST(pTDM,"FA","FR")
			LOCATE FOR sec=90 AND ord=110
		ENDIF
		IF sec=90 AND ord=110 AND mov.totica=0 AND INLIST(pTDM,"FA","FR")
			LOCATE FOR sec=90 AND ord=130
		ENDIF
		*MANEJO DE RENGLONES EN LA FACTURA
		IF sec=90 AND ord=200
			SELECT mov
			IF wcnt > 0
				SKIP
				IF  .NOT. EOF()
					SELECT base
					LOCATE FOR sec=90 AND ord=5
					SKIP -1
				ELSE
					SKIP -1
				ENDIF
			ENDIF
		ENDIF
		f=f+1
		*ENDIF
	ENDSCAN
	SET CONSOLE ON
	SET PRINTER OFF
	SET PRINTER TO DEFAULT
ENDIF
SELECT 0
IF USED('Parametros')
	SELECT parametros
	USE
ENDIF
SELECT 0
IF USED('Enc')
	SELECT enc
	USE
ENDIF
SELECT 0
IF USED('Mov')
	SELECT mov
	USE
ENDIF
SELECT 0
IF USED('Imp')
	SELECT imp
	USE
ENDIF
SELECT 0
IF USED('Base')
	SELECT base
	USE
ENDIF
fxml=ALLTRIM(fxml)
WAIT WINDOW NOWAIT wVer+' - '+'FIN->XML-'+pemp+'-'+pPFE+pNroDcto
RETURN fxml
ENDFUNC
**
FUNCTION GEN_CUFE
	WAIT WINDOW NOWAIT wVer+' - '+'INI->XML-'+pemp+'-'+pPFE+pNroDcto
	wdat=GEN_CUFE_N(pTipoDcto,pNroDcto)
	RETURN wdat
	WAIT WINDOW NOWAIT wVer+' - '+'FIN->XML-'+pemp+'-'+pPFE+pNroDcto
ENDFUNC
**
FUNCTION GEN_CUFE_N
PARAMETER pTDc,pNDc
IF USED('CUFE')
	SELECT CUFE
	USE
ENDIF
SELECT 0
SQLEXEC(gConexEmp,"Select meuuid, cufe from eFac_Enc where Origen='FAC' AND TipoDcto=?pTDc AND NroDcto=?pNDc ","CUFE")
wdat=ALLTRIM(cufe.meuuid)
IF EMPTY(wdat)
	wdat=ALLTRIM(cufe.cufe)
	IF EMPTY(wdat)
		wdat=''
	ELSE
		wdat=LOWER(STRCONV(hash(wdat,3),15))
	ENDIF
ENDIF
IF USED('CUFE')
	SELECT CUFE
	USE
ENDIF
RETURN wdat
ENDFUNC
**
FUNCTION GEN_QR
WAIT WINDOW NOWAIT wVer+' - '+'INI->QR-'+pemp+'-'+pPFE+pNroDcto
PUBLIC wdir
PRIVATE pofbc
m.pofbc=CREATEOBJECT("FoxBarcodeQR")
IF USED('QR')
	SELECT qr
	USE
ENDIF
IF USED('TempQR')
	SELECT tempqr
	USE
ENDIF
SELECT 0
SQLEXEC(gConexEmp,"Select QR from eFac_Enc where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto","QR")
*SELECT 0
*CREATE CURSOR TempQR (qrcode M)
*INSERT INTO TempQR (qrcode) VALUES (qr.qr+wcufe+CHR(13)+'https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey='+wcufe+' ')
wQRCD=qr.qr+wcufe+CHR(13)+CHR(10)
*MESSAGEBOX(wQRCD)
wfile=ALLTRIM("\\"+pSRV+"\eFac\"+gEmpresa+"\QR\"+fnombre())
pofbc.qrbarcodeimage(utf8encode(wQRCD),wfile,12,1)
wfile=ALLTRIM(wfile)+'.JPG'
WAIT WINDOW NOWAIT wVer+' - '+'FIN->QR-'+pemp+'-'+pPFE+pNroDcto
RETURN wfile
ENDFUNC
**
PROCEDURE Firma_xml
PARAMETER pfile
WAIT WINDOW NOWAIT wVer+' - '+'INI->FIRMAR-'+pemp+'-'+pPFE+pNroDcto
IF FILE(pfile)
	fullcommand='\\'+pSRV+'\eFac\Obj\eFac_Sig.exe "firmar"'
	fullcommand=fullcommand+' \\'+pSRV+'\eFac\'+gEmpresa+'\obj\'+pCer
	fullcommand=fullcommand+' "'+pPWD+'" '
*	MESSAGEBOX(fullcommand)
	IF INLIST(pTDM,"FA","FR")
		fullcommand=fullcommand+' "factura" '
	ELSE
		IF INLIST(pTDM,"ND")
			fullcommand=fullcommand+' "nota_debito" '
		ELSE
			IF INLIST(pTDM,"NC")
				fullcommand=fullcommand+' "nota_credito" '
			ELSE
				fullcommand=fullcommand+' "xx" '
			ENDIF
		ENDIF
	ENDIF
	fullcommand=fullcommand+' '+ALLTRIM(pfile)
	fullcommand=fullcommand+' '+STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 7)+'sig.xml'),'\in\','\out\')
	fullcommand=fullcommand+' '+STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 7)+'sig.txt'),'\in\','\out\')
	owinshl=CREATEOBJECT("Wscript.shell")
	shl_res=owinshl.run(fullcommand,1,.T.)
	wfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 7)+'sig.xml'),'\in\','\out\')
ELSE
	wfile=''
ENDIF
WAIT WINDOW NOWAIT wVer+' - '+'FIN->FIRMAR-'+pemp+'-'+pPFE+pNroDcto
RETURN wfile 
ENDPROC
**
FUNCTION Emitir_XML
PARAMETER pfile
WAIT WINDOW NOWAIT wVer+' - '+'INI->EMITIR-'+pemp+'-'+pPFE+pNroDcto
clinea=''
IF FILE(pfile)
	IF substr(pemp,2,1)!='0'
		cfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)),'\out\','\in\')+'_emi.txt'
		IF FILE(cfile)
			nabrir=FOPEN(cfile,10)
			clinea=FGETS(nabrir)
			FCLOSE(nabrir)
		ELSE
			cfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)),'\in\','\out\')+'_emi.txt'
			IF FILE(cfile)
				nabrir=FOPEN(cfile,10)
				clinea=FGETS(nabrir)
				FCLOSE(nabrir)
			ELSE
				clinea='ERROR'
			ENDIF
		ENDIF
	ENDIF
	IF !('EXITO' $ UPPER(clinea))
		fullcommand="\\"+pSRV+"\eFac\Obj\eFac_Sig.exe "
		IF substr(pemp,2,1)='0'
			fullcommand=fullcommand+' "emitir_habilitacion"'
			fullcommand=fullcommand+' \\'+pSRV+'\eFac\'+gEmpresa+'\obj\'+pCer
			fullcommand=fullcommand+' "'+pPWD+'"'
			fullcommand=fullcommand+' "'+ALLTRIM(wTESTSETID)+'"'
			fullcommand=fullcommand+' '+ALLTRIM(pfile)
		ELSE
			fullcommand=fullcommand+' "emitir_produccion"'
			fullcommand=fullcommand+' "\\'+pSRV+'\eFac\'+gEmpresa+'\obj\'+pCer+'"'
			fullcommand=fullcommand+' "'+pPWD+'"'
			fullcommand=fullcommand+' '+ALLTRIM(pfile)
			fullcommand=fullcommand+' '+STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'_emi.xml'),'\in\','\out\')
		ENDIF
		fullcommand=fullcommand+' '+STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'_emi.txt'),'\in\','\out\')
		owinshl=CREATEOBJECT("Wscript.shell")
		shl_res=owinshl.run(fullcommand,1,.T.)
		cfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)),'\in\','\out\')+'_emi.txt'
		nabrir=FOPEN(cfile,10)
		clinea=FGETS(nabrir)
		wborrador=.t.
		FCLOSE(nabrir)
		IF 'EXITO' $ UPPER(clinea) AND FILE(STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'_emi.xml'),'\in\','\out\')) AND substr(pemp,2,1)!='0'
			WAIT WINDOW NOWAIT wVer+' - '+'Se Emitio el XML: '+pfile
			IF FILE(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML')	
				DELETE FILE ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML'
			ENDIF 
			IF FILE(UPPER(STRTRAN(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML','\OUT\','\IN\')))	
				DELETE FILE UPPER(STRTRAN(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML','\OUT\','\IN\'))
			ENDIF 
			IF FILE(UPPER(STRTRAN(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML','\IN\','\OUT\')))	
				DELETE FILE UPPER(STRTRAN(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'.XML','\IN\','\OUT\'))
			ENDIF 
			Crear_Xml(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8)))
			COPY FILE STRTRAN(ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'*.*','\IN\','\OUT\') TO "\\"+pSRV+"\eFac\"+GEMPRESA+"\IN\*.*"
			DELETE FILE ALLTRIM(SUBSTR(PFILE,1,LEN(PFILE) - 8))+'*.*'
			wborrador=.f.
		ELSE
			IF 'EXITO'$UPPER(clinea) AND substr(pemp,2,1)='0'
				wNPfile = CON_eFac()
			ELSE
				MESSAGEBOX('ERROR EN LA TRANSMISION DE LA FACTURA',0,'Emitir')
				wNPfile = UPPER(STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'_emi.txt'),'\in\','\out\'))
			ENDIF
			IF FILE(wNPfile)
				RUN /n notepad &wNPfile
			ELSE
				wborrador=.f.		
			ENDIF
		ENDIF
		DO eFac_TM
	ENDIF
ELSE
	WAIT WINDOW NOWAIT wVer+' - '+'NO existe el XML: '+pfile
ENDIF
wfile=ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'.xml')
IF NOT FILE(wfile)
	wfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'.xml'),'\OUT\','\IN\')
	IF NOT FILE(wfile)
		wfile=STRTRAN(ALLTRIM(SUBSTR(pfile,1,LEN(pfile) - 8)+'.xml'),'\IN\','\OUT\')
	ENDIF
ENDIF
WAIT WINDOW NOWAIT wVer+' - '+'FIN->EMITIR-'+pemp+'-'+pPFE+pNroDcto
RETURN wfile
ENDFUNC
**
FUNCTION CON_eFac
WAIT WINDOW NOWAIT wVer+' - '+'INI->CONSULTAR-'+pemp+'-'+pPFE+pNroDcto
wrep=""
wpuntodeventaid="10000"
wcadena=250
w_empresa='0'
fxml="\\"+pSRV+"\eFac\"+GEMPRESA+"\out\"+fnombre()
wPwdCrt='"'+pEMP+'"'
wfile=ALLTRIM(fxml)+'_res.xml'
xfile=ALLTRIM(fxml)+'_con.txt'
IF FILE(STRTRAN(xfile,'\out\','\in\'))
	WAIT WINDOW NOWAIT wVer+' - '+'XML Exitoso : '+xfile
	xfile=STRTRAN(xfile,'\out\','\in\')
ELSE
	wsw=.f.
	IF FILE(wfile)
		DELETE FILE &wfile
	ENDIF
	IF FILE(xfile)
		DELETE FILE &xfile
	ENDIF
	IF FILE(ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'_err.txt'))
		DELETE FILE FILE &ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'_err.txt')
	ENDIF
	fullcommand="\\"+pSRV+"\eFac\Obj\eFac_Sig.exe "
	IF substr(pemp,2,1)='0'
		fullcommand=fullcommand+' "consultar_habilitacion" '
	ELSE
		fullcommand=fullcommand+' "consultar_produccion" '
	ENDIF
	fullcommand=fullcommand+' \\'+pSRV+'\eFac\'+gEmpresa+'\obj\'+pCer
	fullcommand=fullcommand+' '+pPWD
	IF INLIST(pTDM,"NC","ND")
		fullcommand=fullcommand+' '+wcude
		IF EMPTY(wcude)
			wsw=.t.
		ENDIF
	ELSE 
		fullcommand=fullcommand+' '+wcufe
		IF EMPTY(wcufe)
			wsw=.t.
		ENDIF
	ENDIF
	fullcommand=fullcommand+' '+wfile
	fullcommand=fullcommand+' '+xfile
	owinshl=CREATEOBJECT("Wscript.shell")
	IF EMPTY(wfile) OR EMPTY(xfile) OR EMPTY(xfile) OR EMPTY(pPWD) OR EMPTY(pCer) OR wsw
		WAIT WINDOW 'No se pudo Consultar '+CHR(13)+fxml NOWAIT
		RETURN wfile
	ENDIF	
	TRY
	shl_res=owinshl.run(fullcommand,1,.T.)
	CATCH 
		WAIT WINDOW 'No se pudo Consultar '+CHR(13)+fxml NOWAIT
	ENDTRY 
	cfile=xfile
	nabrir=FOPEN(cfile,10)
	clinea=FGETS(nabrir)
	FCLOSE(nabrir)
	IF 'PENDIENTE' $ UPPER(clinea) OR 'ERROR' $ UPPER(clinea) OR EMPTY(clinea)
		IF FILE(xfile)
			COPY FILE &xfile TO ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'_err.txt')
			DELETE FILE &xfile
		ENDIF
		xfile = ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'_err.txt')
		WAIT WINDOW NOWAIT wVer+' - '+'XML CON ERRORES: '+xfile
	ELSE
		IF FILE(ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8))+'.XML')
			DELETE file ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8))+'.XML'
		ENDIF
		COPY FILE ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'*.*') TO "\\"+pSRV+"\eFac\"+GEMPRESA+"\IN\*.*"
		DELETE FILE ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8)+'*.*')
		WAIT WINDOW NOWAIT wVer+' - '+'XML Exitoso : '+ALLTRIM(SUBSTR(xfile,1,LEN(xfile) - 8))
	ENDIF
ENDIF
WAIT WINDOW NOWAIT wVer+' - '+'FIN->CONSULTAR-'+pemp+'-'+pPFE+pNroDcto
RETURN xfile
ENDFUNC
**
FUNCTION utf8encode
PARAMETER lcstring
LOCAL cutf,i
cutf=""
IF NOT ISNULL(lcstring)
	FOR i=1 TO LEN(lcstring)
		c=ASC(SUBSTR(lcstring,i,1))
		*IF C < 128 &&BETWEEN(C,33,90) OR BETWEEN(C,97,122) OR inlist(C,193,201,205,209,211,218,225,233,237,241,243,250)
		IF c < 128
			cutf=cutf+CHR(c)
		ELSE
			cutf=cutf+CHR(BITOR(192,BITRSHIFT(c,6)))+CHR(BITOR(128,BITAND(c,63)))
		ENDIF
	ENDFOR
ENDIF
cutf=STRTRAN(cutf,'&','Y')
RETURN cutf
ENDFUNC
**
FUNCTION qui_car_esp
PARAMETER pdat
*lstring=STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(ALLTRIM(pdat),'¼','1/4'),'½','1/2'),'Ñ','N'),'Á','A'),'É','E'),'Í','I'),'Ó','O'),'Ú','U'),' ','|'),'&','Y'),'†',''),CHR(160),'')
lstring=STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(STRTRAN(ALLTRIM(pdat),'¼','1/4'),'½','1/2'),' ','|'),'&','Y'),'†',''),CHR(160),'')
IF .NOT. ISNULL(LEN(lstring))
	FOR i=0 TO 255
		IF i<>13 AND .NOT. BETWEEN(i,32,90) AND .NOT. BETWEEN(i,97,122) AND .NOT. inlist(i,193,201,205,209,211,218,225,233,237,241,243,250)
			lstring=STRTRAN(lstring,CHR(i),'')
		ENDIF
	ENDFOR
	*FOR i=1 TO LEN(lstring)
	*	IF ASC(SUBSTR(lstring,i,1))<>13 AND .NOT. ASC(SUBSTR(lstring,i,1))<>10 AND .NOT. BETWEEN(ASC(SUBSTR(lstring,i,1)),32,90) AND .NOT. BETWEEN(ASC(SUBSTR(lstring,i,1)),97,122) AND .NOT. inlist(ASC(SUBSTR(lstring,i,1)),193,201,205,209,211,218,225,233,237,241,243,250)
	*		lstring=STUFF(lstring,AT(SUBSTR(lstring,i,1),lstring),1,'')
	*	ENDIF
	*ENDFOR
	*lstring=STRTRAN(STRTRAN(lstring,CHR(13),'|'),CHR(10),'|')
	DO WHILE '| |'$lstring
		lstring=STRTRAN(lstring,'| |','|')
	ENDDO
	DO WHILE '||'$lstring
		lstring=STRTRAN(lstring,'||','|')
	ENDDO
	DO WHILE '  '$lstring
		lstring=STRTRAN(lstring,'  ',' ')
	ENDDO
	lstring=ALLTRIM(lstring)
	IF SUBSTR(lstring,LEN(lstring),1)='|'
		lstring=SUBSTR(lstring,1,LEN(lstring) - 1)
	ENDIF
ENDIF
RETURN lstring
ENDFUNC
**
FUNCTION eFac_ENLET
PARAMETER pcifra,pmoneda
lstring=xeFac_enlet(pcifra,pmoneda)+CHR(13)+'('+xeFac_enlet1(pcifra,pmoneda)+')'
RETURN lstring
ENDFUNC
**
FUNCTION XeFac_ENLET
PARAMETER mcifra,mmoneda
SET TALK OFF
STORE " " TO mstrcifra,mletras,mparte,msigno
mletras="NO ES UNA CIFRA VALIDA"
STORE 0 TO mpos,mdigito,mdigito1,mdigito2,mcentesimas,jp
DIMENSION uni[9]
DIMENSION dec0[9]
DIMENSION dec[9]
DIMENSION cen00[9]
DIMENSION cen[9]
DIMENSION pos[11]
STORE "UN " TO uni[1]
STORE "DIEZ " TO dec0[1]
STORE "DIECI" TO dec[1]
STORE "CIEN " TO cen00[1]
STORE "CIENTO" TO cen[1]
STORE "" TO pos[1]
STORE "DOS " TO uni[2]
STORE "VEINTE " TO dec0[2]
STORE "VEINTI" TO dec[2]
STORE "DOSCIENTOS " TO cen00[2]
STORE "DOSCIENTOS " TO cen[2]
STORE "" TO pos[2]
STORE "TRES " TO uni[3]
STORE "TREINTA " TO dec0[3]
STORE "TREINTA Y " TO dec[3]
STORE "TRESCIENTOS " TO cen00[3]
STORE "TRESCIENTOS " TO cen[3]
STORE "" TO pos[3]
STORE "CUATRO " TO uni[4]
STORE "CUARENTA " TO dec0[4]
STORE "CUARENTA Y " TO dec[4]
STORE "CUATROCIENTOS " TO cen00[4]
STORE "CUATROCIENTOS " TO cen[4]
STORE "MIL " TO pos[4]
STORE "CINCO " TO uni[5]
STORE "CINCUENTA " TO dec0[5]
STORE "CINCUENTA Y " TO dec[5]
STORE "QUIENIENTOS " TO cen00[5]
STORE "QUIENIENTOS " TO cen[5]
STORE "" TO pos[5]
STORE "SEIS " TO uni[6]
STORE "SESENTA " TO dec0[6]
STORE "SESENTA Y " TO dec[6]
STORE "SEISCIENTOS " TO cen00[6]
STORE "SEISCIENTOS " TO cen[6]
STORE "" TO pos[6]
STORE "SIETE " TO uni[7]
STORE "SETENTA " TO dec0[7]
STORE "SETENTA Y " TO dec[7]
STORE "SETECIENTOS " TO cen00[7]
STORE "SETECIENTOS " TO cen[7]
STORE "MILLONES " TO pos[7]
STORE "OCHO " TO uni[8]
STORE "OCHENTA " TO dec0[8]
STORE "OCHENTA Y " TO dec[8]
STORE "OCHOCIENTOS " TO cen00[8]
STORE "OCHOCIENTOS " TO cen[8]
STORE "" TO pos[8]
STORE "NUEVE " TO uni[9]
STORE "NOVENTA " TO dec0[9]
STORE "NOVENTA Y " TO dec[9]
STORE "NOVECIENTOS " TO cen00[9]
STORE "NOVECIENTOS " TO cen[9]
STORE "" TO pos[9]
STORE "MIL " TO pos[10]
STORE "" TO pos[11]
IF mcifra > -100000000000  AND mcifra < 100000000000 
	IF mcifra < 0
		mcifra=mcifra * -1
		jp=6
	ENDIF
	mstrcifra=STR(mcifra,14,2)
	mletras=""
	FOR mpos=1 TO 11 STEP 1
		mdigito=VAL(SUBSTR(mstrcifra,12 - mpos,1))
		mparte=""
		IF mdigito > 0
			DO CASE
				CASE MOD(mpos,3)=1
					mparte=uni(mdigito)
				CASE MOD(mpos,3)=2 AND mdigito1<>0
					mparte=dec(mdigito)
				CASE MOD(mpos,3)=2 AND mdigito1=0
					mparte=dec0(mdigito)
				CASE MOD(mpos,3)=0 AND (mdigito1<>0 OR mdigito2<>0)
					mparte=cen(mdigito)
				CASE MOD(mpos,3)=0 AND (mdigito1=0 OR mdigito2=0)
					mparte=cen00(mdigito)
			ENDCASE
		ENDIF
		IF VAL(SUBSTR(mstrcifra,1,12 - mpos))<>0
			mletras=mparte+pos(mpos)+mletras
		ENDIF
		mdigito2=mdigito1
		mdigito1=mdigito
	ENDFOR
	IF SUBSTR(mletras,1,11)="UN MILLONES"
		mletras=STUFF(mletras,1,11,"UN MILLON")
	ENDIF
	mletras=STRTRAN(mletras,"DIECIUN","ONCE")
	mletras=STRTRAN(mletras,"CIENTOO","CIENTO")
	mletras=STRTRAN(mletras,"DIECIDOS","DOCE")
	mletras=STRTRAN(mletras,"DIECITRES","TRECE")
	mletras=STRTRAN(mletras,"DIECICUATRO","CATORCE")
	mletras=STRTRAN(mletras,"DIECICINCO","QUINCE")
	mletras=STRTRAN(mletras,"MILLONES MIL","MILLONES")
	mletras=STRTRAN(mletras,"MILLON MIL","MILLON")
	IF RIGHT(mletras,3)="UN "
		mletras=STUFF(mletras,LEN(mletras) - 2,3,"UNO ")
	ENDIF
	IF LEN(ALLTRIM(mletras))=0
		mletras="CERO "
	ENDIF
	DO CASE
		CASE mmoneda='USD'
			mletras=mletras+"DOLARES "
		CASE mmoneda='EUR'
			mletras=mletras+"EUROS "
		CASE mmoneda='GBP'
			mletras=mletras+"LIBRAS "
		CASE mmoneda='BS'
			mletras=mletras+"BOLIVARES "
		OTHERWISE
			mletras=mletras+"PESOS COL "
	ENDCASE
	mcentecimas=SUBSTR(mstrcifra,13,2)
	IF mcentecimas<>"00"
		mletras=mletras+"CON "+mcentecimas+"/100"
	ENDIF
ENDIF
RETURN mletras
ENDFUNC
**
FUNCTION XeFac_ENLET1
PARAMETER tcnro,mmoneda
LOCAL lnent,lcret,lccad,lnterna,lnuni,lNDec,lncent,lnfrac
lnent=INT(tcnro)
lnfrac=(tcnro - lnent) * 100
lcret=''
lnterna=1
DO WHILE lnent>0
	lccad=''
	lnuni=MOD(lnent,10)
	lnent=INT(lnent / 10)
	lNDec=MOD(lnent,10)
	lnent=INT(lnent / 10)
	lncent=MOD(lnent,10)
	lnent=INT(lnent / 10)
	DO CASE
		CASE lnuni=1
			lccad='ONE '+lccad
		CASE lnuni=2
			lccad='TWO '+lccad
		CASE lnuni=3
			lccad='THREE '+lccad
		CASE lnuni=4
			lccad='FOUR '+lccad
		CASE lnuni=5
			lccad='FIVE '+lccad
		CASE lnuni=6
			lccad='SIX '+lccad
		CASE lnuni=7
			lccad='SEVEN '+lccad
		CASE lnuni=8
			lccad='EIGHT '+lccad
		CASE lnuni=9
			lccad='NINE '+lccad
	ENDCASE
	DO CASE
		CASE lNDec=1
			DO CASE
				CASE lnuni=0
					lccad='TEN '
				CASE lnuni=1
					lccad='ELEVEN '
				CASE lnuni=2
					lccad='TWELVE '
				CASE lnuni=3
					lccad='THIRTEEN '
				CASE lnuni=4
					lccad='FOURTEEN '
				CASE lnuni=5
					lccad='FIFTEEN '
				CASE lnuni=6
					lccad='SIXTEEN '
				CASE lnuni=7
					lccad='SEVENTEEN '
				CASE lnuni=8
					lccad='EIGHTEEN '
				CASE lnuni=9
					lccad='NINETEEN '
			ENDCASE
		CASE lNDec=2
			lccad='TWENTY '+lccad
		CASE lNDec=3
			lccad='THIRTY '+lccad
		CASE lNDec=4
			lccad='FORTY '+lccad
		CASE lNDec=5
			lccad='FIFTY '+lccad
		CASE lNDec=6
			lccad='SIXTY '+lccad
		CASE lNDec=7
			lccad='SEVENTY '+lccad
		CASE lNDec=8
			lccad='EIGHTY '+lccad
		CASE lNDec=9
			lccad='NINETY '+lccad
	ENDCASE
	DO CASE
		CASE lncent=1
			lccad='ONE HUNDRED '+lccad
		CASE lncent=2
			lccad='TWO HUNDRED '+lccad
		CASE lncent=3
			lccad='THREE HUNDRED '+lccad
		CASE lncent=4
			lccad='FOUR HUNDRED '+lccad
		CASE lncent=5
			lccad='FIVE HUNDRED '+lccad
		CASE lncent=6
			lccad='SIX HUNDRED '+lccad
		CASE lncent=7
			lccad='SEVEN HUNDRED '+lccad
		CASE lncent=8
			lccad='EIGHT HUNDRED '+lccad
		CASE lncent=9
			lccad='NINE HUNDRED '+lccad
	ENDCASE
	DO CASE
		CASE lnterna=1
			lccad=lccad
		CASE lnterna=2
			lccad=lccad+'THOUSAND '
		CASE lnterna=3
			lccad=lccad+'MILLON '
		CASE lnterna=4
			lccad=lccad+'BILLON '
	ENDCASE
	lcret=lccad+lcret
	lnterna=lnterna+1
ENDDO
IF lnterna=1
	lcret='ZERO '
ENDIF
DO CASE
	CASE mmoneda='USD'
		lcret=lcret+"DOLLARS "
	CASE mmoneda='EUR'
		lcret=lcret+"EUROS "
	CASE mmoneda='GBP'
		lcret=lcret+"BRITISH POUND "
	CASE mmoneda='BS'
		lcret=lcret+"BOLIVARES "
	OTHERWISE
		lcret=lcret+"PESOS COP "
ENDCASE
mcentecimas=STR(lnfrac,2,0)
IF mcentecimas<>"00"
	lcret=lcret+"AND "+mcentecimas+"/100"
ENDIF
RETURN lcret
ENDFUNC
**
PROCEDURE eFac_PDF
	WAIT WINDOW NOWAIT wVer+' - '+'INI->PDF-'+pemp+'-'+pPFE+pNroDcto
	fpdf="\\"+pSRV+"\eFac\"+gEmpresa+"\PDF\"+fnombre()+".PDF"
	fxml="\\"+pSRV+"\eFac\"+gEmpresa+"\IN\"+fnombre()+".xml"
	IF substr(pemp,2,1)='0' AND !FILE(fxml)
		xxml="\\"+pSRV+"\eFac\"+gEmpresa+"\IN\"+fnombre()+"_sig.xml"
		IF FILE(xxml)
			COPY FILE &xxml TO &fxml
		ENDIF
	ENDIF 
	IF FILE(fxml)
		IF FILE(fpdf)
			wmes = MESSAGEBOX('¿Desea Sobreescribir el archivo PDF ?'+CHR(13)+fnombre()+".PDF",4+32+256,'eFac')
		ELSE
			wmes = 6
		ENDIF
		IF wmes = 6
			mna1="'"+pnrodcto+".PDF'"
			mna2="'"+ALLTRIM(pNombreFormato)+"'"
			LOCAL losession,lnretval
			losession=xfrx("XFRX#INIT")
			lnRetVal=loSession.SetParams(&MNA1,,.T.,,,,"PDF")
			wcopia=0
			wtitulo="Copia Electronica"
			IF lnretval=0
				losession.setpermissions(.T.,.F.,.F.,.F.)
				loSession.ProcessReport(&MNA2)
				losession.finalize()
				cotiza=pnrodcto+".PDF"
				TRY
				DELETE FILE &fpdf
				CATCH 
					WAIT WINDOW 'No se pudo Sobreescribir '+CHR(13)+fnombre()+".PDF" NOWAIT
				ENDTRY 
				TRY
					COPY FILE &cotiza TO &fpdf
				CATCH 
					WAIT WINDOW 'No se pudo Sobreescribir '+CHR(13)+fnombre()+".PDF" NOWAIT
				ENDTRY 
				wdir="\\"+pSRV+"\eFac\"+gEmpresa+"\ADN\"
				IF DIRECTORY(wdir) AND FILE(fpdf) AND FILE(fxml)
					wdir=wdir+STR(YEAR(curencabezado.fecha),4)
					IF month(curencabezado.fecha) < 10
						wdir=wdir+'0'+STR(month(curencabezado.fecha),1)
					ELSE
						wdir=wdir+STR(month(curencabezado.fecha),2)
					ENDIF
					IF day(curencabezado.fecha) < 10
						wdir=wdir+'0'+STR(day(curencabezado.fecha),1)
					ELSE
						wdir=wdir+STR(day(curencabezado.fecha),2)
					ENDIF
					IF !DIRECTORY(wdir)
						MKDIR &wdir
					ENDIF
					wdir=wdir+"\*.*"
					COPY FILE &fpdf TO &wdir
					COPY FILE &fxml TO &wdir
				ENDIF 
				fullcommand=fpdf
				owinshl=CREATEOBJECT("Wscript.shell")
				shl_res=owinshl.run(fullcommand,1,.F.)
				*IF pTipoSalida!=9
				*	wTipoSalida=pTipoSalida
				*ENDIF
				*pTipoSalida=9
			ENDIF
		ENDIF
	ELSE
		WAIT WINDOW fxml NOWAIT
	****
	ENDIF
	WAIT WINDOW NOWAIT wVer+' - '+'FIN->PDF-'+pemp+'-'+pPFE+pNroDcto
	RETURN
ENDPROC
**
FUNCTION fnombre
wfile=pNit+'-'+pPFE+ALLTRIM(pnrodcto)
RETURN wfile
ENDFUNC
**
FUNCTION eFac_Mail
PARAMETERS wsw
	LOCAL wAsunto,wAdjunto,wCuerpo,wDe,wPara,wCCo
	WAIT WINDOW NOWAIT wVer+' - '+'INI->eMail-'+pemp+'-'+pPFE+pNroDcto
	wmails=''
	IF wsw
		IF USED('mail')
			SELECT mail
			USE
		ENDIF
		SELECT 0
		SQLEXEC(gConexEmp,"Select email from eFac_Enc where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto ","mail")
		SELECT mail
		IF .NOT.EOF()
			wmails=ALLTRIM(LOWER(email))
		ENDIF
		USE
	ELSE
		wmails='efac@efac.com.co'
	ENDIF
	fpdf="\\"+pSRV+"\eFac\"+gEmpresa+"\PDF\"+fnombre()+".pdf"
	fxml="\\"+pSRV+"\eFac\"+gEmpresa+"\IN\"+fnombre()+".xml"
	IF FILE(fpdf) AND FILE(fxml)
		DO efac_ZIP
*El correo electrónico deberá tener las siguientes características:
*• Asunto: NIT del Facturador Electrónico; Nombre del Facturador Electrónico; Número del Documento Electrónico (campo cbc:ID); Código del tipo de documento según tabla 6.1.3.; Nombre comercial del facturador; Linea de negocio (este ultimo opcional, acuerdo comercial entre las partes).
*• Archivos adjuntos: Un archico .ZIP que contectan, un Attached Document según la especificación del presente anexo, es decir que contiene el ApplicationResponse y la factura electrónica en el contenedor electrónico. De manera opcional se puede anexar el PDF de la representación gráfica.
*• Peso máximo por envío: 2 Mega.
*• Cuerpo del correo: Correo de autorespuesta: Corresponde al correo electrónico en donde el Adquiriente podrá enviar los eventos de Acuse de recibo, aceptación, rechazo y/o recepción de bienes y/o de prestación de servicios.
*• Capacidad del buzón de recepción: Garantizar un espacio de recepción disponible en cualquier momento de mínimo de 20 Megas
		wAsunto=pNit+' '+pRZS+' '+pPFE+ALLTRIM(pnrodcto)
		xsDcto=''
		DO CASE 
			CASE pTDM='NC'
				wAsunto=wAsunto+' 91'
				xsDcto="Nota Crédito electrónica"
			CASE pTDM='ND'
				wAsunto=wAsunto+' 92'
				xsDcto="Nota Débito electrónica"
			CASE INLIST(pTDM,'FA','FR')
				wAsunto=wAsunto+' 01'
				xsDcto="Factura electrónica de venta"
		ENDCASE

        DO CASE 
        CASE pEmp= "01" 
            xsEmpr = "pcgc"
        CASE pEmp= "02"
            xsEmpr = "bros"
        CASE pEmp= "03"
            xsEmpr = "g10sas"
        CASE pEmp= "11" 
            xsEmpr = "flordeloto"
        CASE pEmp= "12" 
            xsEmpr = "bioquifar"
        CASE pEmp= "13" 
            xsEmpr = "labquifar"
        CASE pEmp= "14" 
            xsEmpr = "anglopharma"
        CASE pEmp= "15" 
            xsEmpr = "ophalac"
        CASE pEmp= "16" 
            xsEmpr = "matprifar"
        CASE pEmp= "21" 
            xsEmpr = "aldriston"
        CASE pEmp= "22" 
            xsEmpr = "gonher"
        CASE pEmp= "31" 
            xsEmpr = "vicar"
        CASE pEmp= "32" 
            xsEmpr = "sifagro"
        CASE pEmp= "33" 
            xsEmpr = "castrobotero"
        CASE pEmp= "34" 
            xsEmpr = "jlcu"
        CASE pEmp= "35" 
            xsEmpr = "lb"
        OTHERWISE 
            xsBody = "Empresa de pruebas eFac " + pEmp
            xsEmpr = "setp"
        ENDCASE 
        
		xsLink1 = "https://www.efac.com.co/" + xsEmpr
		xsLink1 = xsLink1+"/?docid="+pPFE+ALLTRIM(pnrodcto)
		xsLink1 = xsLink1+"&?feid="+ALLTRIM(wCUFE)
		xsLink2 = "https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey="+ALLTRIM(wCUFE)

		wCuerpo=pRZS+" le informa que se generó la "+xsDcto+" # "+pPFE+ALLTRIM(pnrodcto)+"<br/>"+"<br/>"
		wCuerpo=wCuerpo+"Para Aprobar/Rechazar siga el siguiente link: "
		wCuerpo=wCuerpo+"<a href=" + xsLink1 + ">eFac</a>"
		wCuerpo=wCuerpo+"<br/>"
		wCuerpo=wCuerpo+"Para validar siga el siguiente link: "
		wCuerpo=wCuerpo+"<a href=" + xsLink2 + ">DIAN</a>"
		wCuerpo=wCuerpo+"<br/>"
		wCuerpo=wCuerpo+"<br/>"
		wCuerpo=wCuerpo+"--<br/>"
		wCuerpo=wCuerpo+"Facturación Electrónica<br/>"
		wCuerpo=wCuerpo+pRZS
		pFrom='"'+PROPER(pRZS)+'" <'+xsEmpr+'@efac.com.co>'
		loMail=CREATEOBJECT("Cdo2000")
		WITH loMail
		   .cServer="smtp.mi.com.co"
		   .nServerPort=465
		   .lUseSSL=.T.
		   
		   .nAuthenticate=1
		   .cUserName="efac@efac.com.co"
		   .cPassword="h.LncJ4NEfR7"

		   .cFrom=pFrom
		   .cTo=wmails
		   .cBCC=pCCo
		   .cSubject=wAsunto
		   .cAttachment=eFacZip
		   .cHtmlBody=wCuerpo
		ENDWITH

		werr=''
		IF loMail.Send() > 0
			FOR i=1 TO loMail.GetErrorCount()
				?i,loMail.Geterror(i)
				werr=loMail.Geterror(i)
			ENDFOR
		ELSE
			werr="Email enviado a"
		ENDIF
		loMail.ClearErrors()
		MESSAGEBOX(ALLTRIM(werr)+CHR(13)+wmails,0,'eFac_Mail-'+pCCo)
	ELSE
		IF  .NOT. FILE(fpdf) AND  .NOT. FILE(fxml)
			WAIT WINDOW NOWAIT wVer+' - '+ALLTRIM(fpdf)+CHR(13)+ALLTRIM(fxml)+CHR(13)+'NO EXISTE'
		ELSE
			IF  .NOT. FILE(fpdf)
				WAIT WINDOW NOWAIT wVer+' - '+ALLTRIM(fpdf)+CHR(13)+'NO EXISTE'
			ELSE
				WAIT WINDOW NOWAIT wVer+' - '+ALLTRIM(fxml)+CHR(13)+'NO EXISTE'
			ENDIF
		ENDIF
	ENDIF
	WAIT WINDOW NOWAIT wVer+' - '+'FIN->eMail-'+pemp+'-'+pPFE+pNroDcto
RETURN
ENDFUNC
**
**
PROCEDURE Crear_Xml
PARAMETERS wArc
WAIT WINDOW NOWAIT wVer+' - '+'INI->Crear_Xml-'+pemp+'-'+pPFE+pNroDcto
wArc_EMI=wArc+'_EMI.XML'
wArc_SIG=wArc+'_SIG.XML'
wArc_XML=wArc+'.XML'
wTxt_EMI=FILETOSTR(wArc_EMI)
wTxt_SIG=FILETOSTR(wArc_SIG)
IF SUBSTR(pemp,2,1)='0'
	wPEID='2'
ELSE
	wPEID='1'
ENDIF

WTIME=DATETIME()
wDATE=DATE()
WHOR=hour(WTIME)+5
IF hour(WTIME)>19
	wDATE=wDATE+1
	WHOR=WHOR-24
ENDIF
IF WHOR<10
	WHOR='0'+ALLTRIM(STR(WHOR))
ELSE
	WHOR=ALLTRIM(STR(WHOR))
ENDIF
WHOR=WHOR+SUBSTR(TTOC(WTIME,3),14,10)+'-05:00'

WFEC=ALLTRIM(STR(YEAR(wDATE)))+'-'
IF MONTH(wDATE) < 10
	WFEC=WFEC+'0'
ENDIF
WFEC=WFEC+ALLTRIM(STR(MONTH(wDATE)))+'-'
IF DAY(wDATE) < 10
	WFEC=WFEC+'0'
ENDIF
WFEC=WFEC+ALLTRIM(STR(DAY(wDATE)))
lco=UTF8ENCODE(CHR(243))
lcFecha=STREXTRACT(FILETOSTR(wArc_EMI),'<cbc:IssueDate>','</cbc:IssueDate>')
lcHora=STREXTRACT(FILETOSTR(wArc_EMI),'<cbc:IssueTime>','</cbc:IssueTime>')
lcFec=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:IssueDate>','</cbc:IssueDate>')
lcRNObl=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:RegistrationName>','</cbc:RegistrationName>',1,0)
lcRNAdq=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:RegistrationName>','</cbc:RegistrationName>',3,0)
xcNTObl=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:CompanyID','</cbc:CompanyID>',1)
IF SUBSTR(xcNTObl,22,4)='Agen'
	*<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (DirecciÃ³n de Impuestos y Aduanas Nacionales)" schemeID="0" schemeName="31">900326502</cbc:CompanyID>
	lcNTObl=' '+SUBSTR(xcNTObl,AT('schemeID="',xcNTObl,1),AT('>',xcNTObl,1)-AT('schemeID="',xcNTObl,1))
	lcNTObl=lcNTObl+' '+SUBSTR(xcNTObl,AT('schemeAgencyID="',xcNTObl,1),AT('schemeAgencyName',xcNTObl,1)-AT('schemeAgencyID="',xcNTObl,1)-1)
	lcNTObl=lcNTObl+SUBSTR(xcNTObl,AT('">',xcNTObl,1)+1,200)
ELSE
	*<cbc:CompanyID schemeID="0" schemeName="31" schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">900326502</cbc:CompanyID>
	lcNTObl=' '+SUBSTR(xcNTObl,AT('schemeID="',xcNTObl,1),AT('schemeAgencyName',xcNTObl,1)-AT('schemeID="',xcNTObl,1))
	lcNTObl=lcNTObl+SUBSTR(xcNTObl,AT('">',xcNTObl,1)+1,200)
ENDIF
xcNTAdq=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:CompanyID','</cbc:CompanyID>',3)
IF SUBSTR(xcNTAdq,22,4)='Agen'
	*<cbc:CompanyID schemeAgencyID="195" schemeAgencyName="CO, DIAN (DirecciÃ³n de Impuestos y Aduanas Nacionales)" schemeID="0" schemeName="31">900326502</cbc:CompanyID>
	lcNTAdq=' '+SUBSTR(xcNTAdq,AT('schemeID="',xcNTAdq,1),AT('>',xcNTObl,1)-AT('schemeID="',xcNTAdq,1))
	lcNTAdq=lcNTAdq+' '+SUBSTR(xcNTAdq,AT('schemeAgencyID="',xcNTAdq,1),AT('schemeAgencyName',xcNTAdq,1)-AT('schemeAgencyID="',xcNTAdq,1)-1)
	lcNTAdq=lcNTAdq+SUBSTR(xcNTAdq,AT('">',xcNTAdq,1)+1,200)
ELSE
	*<cbc:CompanyID schemeID="0" schemeName="31" schemeAgencyID="195" schemeAgencyName="CO, DIAN (Dirección de Impuestos y Aduanas Nacionales)">900326502</cbc:CompanyID>
	lcNTAdq=' '+SUBSTR(xcNTAdq,AT('schemeID="',xcNTAdq,1),AT('schemeAgencyName',xcNTAdq,1)-AT('schemeID="',xcNTAdq,1))
	lcNTAdq=lcNTAdq+SUBSTR(xcNTAdq,AT('">',xcNTAdq,1)+1,200)
ENDIF

lcTLObl=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:TaxLevelCode','</cbc:TaxLevelCode>',1)
lcTLAdq=STREXTRACT(FILETOSTR(wArc_SIG),'<cbc:TaxLevelCode','</cbc:TaxLevelCode>',2)
*<AttachedDocument xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ccts="urn:un:unece:uncefact:data:specification:CoreComponentTypeSchemaModule:2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#" xmlns="urn:oasis:names:specification:ubl:schema:xsd:AttachedDocument-2">
*<?xml version="1.0"?>
*<AttachedDocument xmlns="urn:oasis:names:specification:ubl:schema:xsd:AttachedDocument-2" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#"
*  xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"
*  xmlns:ccts="urn:un:unece:uncefact:data:specification:CoreComponentTypeSchemaModule:2"
*  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
*  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
TEXT TO wTxt_XML TEXTMERGE PRETEXT 1+2+4 NOSHOW
<AttachedDocument xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ccts="urn:un:unece:uncefact:data:specification:CoreComponentTypeSchemaModule:2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2" xmlns:xades="http://uri.etsi.org/01903/v1.3.2#" xmlns:xades141="http://uri.etsi.org/01903/v1.4.1#" xmlns="urn:oasis:names:specification:ubl:schema:xsd:AttachedDocument-2">
  <cbc:UBLVersionID>UBL 2.1</cbc:UBLVersionID>
  <cbc:CustomizationID>Documentos adjuntos</cbc:CustomizationID>
  <cbc:ProfileID>DIAN 2.1</cbc:ProfileID>
  <cbc:ProfileExecutionID><<wPEID>></cbc:ProfileExecutionID>
  <cbc:ID><<wCUFE>></cbc:ID>
  <cbc:IssueDate><<WFEC>></cbc:IssueDate>
  <cbc:IssueTime><<WHOR>></cbc:IssueTime>
  <cbc:DocumentType>Contenedor de Factura Electr<<lco>>nica</cbc:DocumentType>
  <cbc:ParentDocumentID><<pPFE+pNroDcto>></cbc:ParentDocumentID>
  <cac:SenderParty>
    <cac:PartyTaxScheme>
      <cbc:RegistrationName><<lcRNObl>></cbc:RegistrationName>
      <cbc:CompanyID<<lcNTObl>></cbc:CompanyID>
      <cbc:TaxLevelCode<<lcTLObl>></cbc:TaxLevelCode>
      <cac:TaxScheme>
        <cbc:ID>01</cbc:ID>
        <cbc:Name>IVA</cbc:Name>
      </cac:TaxScheme>
    </cac:PartyTaxScheme>
  </cac:SenderParty>
  <cac:ReceiverParty>
    <cac:PartyTaxScheme>
      <cbc:RegistrationName><<lcRNAdq>></cbc:RegistrationName>
      <cbc:CompanyID<<lcNTAdq>></cbc:CompanyID>
      <cbc:TaxLevelCode<<lcTLAdq>></cbc:TaxLevelCode>
      <cac:TaxScheme>
        <cbc:ID>01</cbc:ID>
        <cbc:Name>IVA</cbc:Name>
      </cac:TaxScheme>
    </cac:PartyTaxScheme>
  </cac:ReceiverParty>
  <cac:Attachment>
    <cac:ExternalReference>
      <cbc:MimeCode>text/xml</cbc:MimeCode>
      <cbc:EncodingCode>UTF-8</cbc:EncodingCode>
      <cbc:Description><![CDATA[<<wTxt_SIG>>]]></cbc:Description>
    </cac:ExternalReference>
  </cac:Attachment>
  <cac:ParentDocumentLineReference>
    <cbc:LineID>1</cbc:LineID>
    <cac:DocumentReference>
      <cbc:ID><<pPFE+pNroDcto>></cbc:ID>
      <cbc:UUID schemeName="CUFE-SHA384"><<wCUFE>></cbc:UUID>
      <cbc:IssueDate><<lcFec>></cbc:IssueDate>
      <cbc:DocumentType>ApplicationResponse</cbc:DocumentType>
      <cac:Attachment>
        <cac:ExternalReference>
          <cbc:MimeCode>text/xml</cbc:MimeCode>
          <cbc:EncodingCode>UTF-8</cbc:EncodingCode>
          <cbc:Description><![CDATA[<<wTxt_EMI>>]]></cbc:Description>
        </cac:ExternalReference>
      </cac:Attachment>
      <cac:ResultOfVerification>
        <cbc:ValidatorID>Unidad Especial Direcci<<lco>>n de Impuestos Y Aduanas Nacionales</cbc:ValidatorID>
        <cbc:ValidationResultCode>1</cbc:ValidationResultCode>
        <cbc:ValidationDate><<lcFecha>></cbc:ValidationDate>
        <cbc:ValidationTime><<lcHora>></cbc:ValidationTime>
      </cac:ResultOfVerification>
    </cac:DocumentReference>
  </cac:ParentDocumentLineReference>
</AttachedDocument>
ENDTEXT

*wTxt_XML=UTF8ENCODE(wTxt_XML)
STRTOFILE(wTxt_XML,wArc_XML,4)
WAIT WINDOW NOWAIT wVer+' - '+'FIN->Crear_Xml-'+pemp+'-'+pPFE+pNroDcto
RETURN
ENDPROC

PROCEDURE eFac_TM
WAIT WINDOW NOWAIT wVer+' - '+'INI->eFac_TM-'+pemp+'-'+pPFE+pNroDcto
	IF USED("TRADEMAS")
		SELECT TRADEMAS
		USE
	ENDIF
	SELECT 0
	SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'PRFJ',?pTipoDcto,?pNroDcto,?pPFE,?datetime() ","")
	SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'CONSE',?pTipoDcto,?pNroDcto,?pCodigoConse,?datetime() ","")
	mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
	If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
		Return 0
	ENDif
	Select TRADEMAS
	GO TOP 
	IF TRADEMAS.TR_EFAC=.f.
		wfile=con_efac()
		IF FILE(wfile)
			DELETE FILE &wfile
		ENDIF
		lcArchivo="\\"+pSRV+"\eFac\"+gempresa+"\in\"
		lcArchivo=lcArchivo+ALLTRIM(fnombre())+"_res.XML"
		IF FILE(lcArchivo)
			wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>',2)
			IF EMPTY(wcufe)
				wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>')
				IF EMPTY(wcufe)
					wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUDE-SHA384">','</cbc:UUID>',2)
				ENDIF
			ENDIF
			SELECT 0
			IF SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'CUFE',?pTipoDcto,?pNroDcto,?wcufe,?datetime() ","") > 0
				lcFecha=STREXTRACT(FILETOSTR(lcArchivo),"<cbc:IssueDate>","</cbc:IssueDate>")
				lcHora=STREXTRACT(FILETOSTR(lcArchivo),"<cbc:IssueTime>","</cbc:IssueTime>")
				wFc_eFac=ctot(lcFecha+' '+SUBSTR(lcHora,1,8))
				SELECT 0
				IF SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'FECHA',?pTipoDcto,?pNroDcto,?wFc_eFac,?wFc_eFac ","") > 0
					SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'TR_EFAC',?pTipoDcto,?pNroDcto,'1',?wFc_eFac ","")
					WAIT WINDOW NOWAIT wVer+' - '+'Se Emitio el XML: '+lcArchivo+CHR(13)+lcFecha+' '+SUBSTR(lcHora,1,8)+CHR(13)+wcufe
				ENDIF
			ENDIF
			SELECT TRADEMAS
			mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
			If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
				oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
				Return 0
			ENDif
		ENDIF
	ENDIF
	Select TRADEMAS
	GO TOP 
	IF TRADEMAS.FC_EFAC < pFec
		wfile="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fnombre())+"_res.XML"
		lcArchivo="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fnombre())+"_emi.XML"
		IF !FILE(lcArchivo) AND TRADEMAS.TR_EFAC 
			IF !FILE(wfile)
				wfile=con_efac()
				IF FILE(wfile)
					DELETE FILE &wfile
				ENDIF
				wfile="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fnombre())+"_res.XML"
			ENDIF
			IF FILE(wfile)
				COPY FILE &wfile TO &lcArchivo
			ENDIF
		ENDIF
		IF FILE(lcArchivo)
			lcFecha=STREXTRACT(FILETOSTR(lcArchivo),"<cbc:IssueDate>","</cbc:IssueDate>")
			lcHora=STREXTRACT(FILETOSTR(lcArchivo),"<cbc:IssueTime>","</cbc:IssueTime>")
			wFc_eFac=ctot(lcFecha+' '+SUBSTR(lcHora,1,8))
			SELECT 0
			IF SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'FECHA',?pTipoDcto,?pNroDcto,?wFc_eFac,?wFc_eFac ","") > 0
				WAIT WINDOW NOWAIT wVer+' - '+'Se Emitio el XML: '+lcArchivo+CHR(13)+lcFecha+' '+SUBSTR(lcHora,1,8)
			ELSE
				WAIT WINDOW 'Se Emitio el XML: '+lcArchivo+CHR(13)+'Error en FC_eFac'
			ENDIF
			SELECT TRADEMAS
			mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
			If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
				oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
				Return 0
			ENDif
		ENDIF
	ENDIF
	Select TRADEMAS
	GO TOP 
	IF LEN(ALLTRIM(TRADEMAS.MEUUID))<96
		lcArchivo="\\"+pSRV+"\eFac\"+gempresa+"\in\"
		lcArchivo=lcArchivo+ALLTRIM(fnombre())+"_EMI.XML"
		IF FILE(lcArchivo)
			wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeID="1" schemeName="CUFE-SHA384">','</cbc:UUID>')
			IF EMPTY(wcufe)
				wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeID="2" schemeName="CUFE-SHA384">','</cbc:UUID>')
				IF EMPTY(wcufe)
					wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>',2)
					IF EMPTY(wcufe)
						wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>',1)
					ENDIF
				ENDIF
			ENDIF
			IF EMPTY(wcufe)
				wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeID="1" schemeName="CUDE-SHA384">','</cbc:UUID>')
				IF EMPTY(wcufe)
					wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeID="2" schemeName="CUDE-SHA384">','</cbc:UUID>')
					IF EMPTY(wcufe)
						wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUDE-SHA384">','</cbc:UUID>',2)
						IF EMPTY(wcufe)
							wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUDE-SHA384">','</cbc:UUID>',1)
						ENDIF
					ENDIF
				ENDIF
			ENDIF
			SELECT 0
			IF SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'CUFE',?pTipoDcto,?pNroDcto,?wcufe,?datetime() ","") > 0
				WAIT WINDOW NOWAIT wVer+' - '+'Se Emitio el XML: '+lcArchivo
			ELSE
				WAIT WINDOW 'Se Emitio el XML: '+lcArchivo+CHR(13)+'Error en CUFE'
			ENDIF
			SELECT TRADEMAS
			mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
			If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
				oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
				Return 0
			ENDif
		ENDIF
	ENDIF
	Select TRADEMAS
	GO TOP 
	IF LEN(ALLTRIM(TRADEMAS.MEUUID))<96
		lcArchivo="\\"+pSRV+"\eFac\"+gempresa+"\in\"
		lcArchivo=lcArchivo+ALLTRIM(fnombre())+"_SIG.XML"
		IF FILE(lcArchivo)
			wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>',2)
			IF EMPTY(wcufe)
				wcufe=STREXTRACT(FILETOSTR(lcArchivo),'<cbc:UUID schemeName="CUFE-SHA384">','</cbc:UUID>')
			ENDIF
			SELECT 0
			IF SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'CUFE',?pTipoDcto,?pNroDcto,?wcufe,?datetime() ","") > 0
				WAIT WINDOW NOWAIT wVer+' - '+'Se Emitio el XML: '+lcArchivo
			ELSE
				WAIT WINDOW 'Se Emitio el XML: '+lcArchivo+CHR(13)+'Error en CUFE'
			ENDIF
			SELECT TRADEMAS
			mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
			If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
				oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
				Return 0
			ENDif
		ENDIF
	ENDIF
	Select TRADEMAS
	GO TOP 
WAIT WINDOW NOWAIT wVer+' - '+'FIN->eFac_TM-'+pemp+'-'+pPFE+pNroDcto
RETURN
ENDPROC

FUNCTION eFac_ScE
	*Encrypt(cStringtoEncrypt, cSecretKey[,  [, nEncryptionMode[, nPaddingType[, nKeySize[, nBlockSize[, cIV]]]]]])
	PARAMETERS lcData
	PRIVATE lcKey,lcPlaintext,lcCipherText,lcDecipherText
	lcKey="eFac_PCgc_092009"
	lcData=STRTRAN(ALLTRIM(lcData),CHR(0),'')
	IF LEN(lcData)!=0 
		lcCipher=ENCRYPT(lcData,lcKey)
	ELSE
		lcCipher=''
	ENDIF
	RETURN ALLTRIM(lcCipher)
ENDFUNC 

FUNCTION eFac_ScD
	*Decrypt(cEncryptString, cSecretKey[, nDecryptionType[, nDecryptionMode[, nPaddingType[, nKeySize[, nBlockSize[, cIV]]]]]])
	PARAMETERS lcCipher
	PRIVATE lcKey,lcPlaintext,lcCipherText,lcDecipherText,Dekripnya,xData
	lcKey="eFac_PCgc_092009"
	lcCipher=STRTRAN(ALLTRIM(lcCipher),CHR(0),'')
	IF LEN(lcCipher)!=0 
		Dekripnya=DECRYPT(lcCipher,lcKey)
	ELSE
		Dekripnya=''
	ENDIF
	Dekripnya=ALLTRIM(STRTRAN(Dekripnya,CHR(0),''))
	RETURN ALLTRIM(Dekripnya)
ENDFUNC

FUNCTION eFac_Zip
	SELECT 0
	lcArc_adj=pTDM+pNIT
	SQLEXEC(gConexEmp,"execute dbo.eFac_TM 'FL_EFAC',?pTipoDcto,?pNroDcto,?lcArc_adj,?datetime() ","")
	mstrsql="SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
	If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos del encabezado")
		Return 0
	ENDif
	Select TRADEMAS
	GO TOP 
	lcArc_adj="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fnombre())+".XML"
	lceFac_adj="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(ar_efac)+".XML"
	IF FILE(lceFac_adj) 
		ERASE &lceFac_adj
	ENDIF
	COPY FILE &lcArc_adj TO &lceFac_adj

	lcArc_sig="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fnombre())+"_SIG.XML"
	lceFac_Sig="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fl_efac)+".XML"
	IF FILE(lceFac_Sig) 
		ERASE &lceFac_Sig
	ENDIF
	COPY FILE &lcArc_sig TO &lceFac_Sig

	lcArc_pdf="\\"+pSRV+"\eFac\"+gempresa+"\pdf\"+ALLTRIM(fnombre())+".PDF"
	lceFac_pdf="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(fl_efac)+".PDF"
	IF FILE(lceFac_pdf) 
		ERASE &lceFac_pdf
	ENDIF
	COPY FILE &lcArc_pdf TO &lceFac_pdf

	eFacZip="\\"+pSRV+"\eFac\"+gempresa+"\in\"+ALLTRIM(ad_efac)+".ZIP"
	
	IF FILE(eFacZip) && Borro Zip si existe
		ERASE eFacZip
	ENDIF
	STRTOFILE(CHR(0x50)+CHR(0x4B)+CHR(0x05)+CHR(0x06)+REPLICATE(CHR(0),18),eFacZip)
	oShell = CREATEOBJECT("Shell.Application")
	IF TYPE('oShell')='O'
		oFolder = oShell.NameSpace("&eFacZip")
		IF TYPE('oFolder')='O'
			WAIT 'Procesando Archivo '+LOWER(lceFac_adj) WINDOW NOWAIT
			IF FILE(lceFac_adj)
				oFolder.CopyHere(lceFac_adj)
			ENDIF
			INKEY(1)
			WAIT CLEAR
			WAIT 'Procesando Archivo '+LOWER(lceFac_Sig) WINDOW NOWAIT
			IF FILE(lceFac_Sig)
				oFolder.CopyHere(lceFac_Sig)
			ENDIF
			INKEY(1)
			WAIT CLEAR
			WAIT 'Procesando Archivo '+LOWER(lceFac_pdf) WINDOW NOWAIT
			IF FILE(lceFac_pdf)
				oFolder.CopyHere(lceFac_pdf)
			ENDIF
			INKEY(1)
			WAIT CLEAR
	
			lceFac_adjs="\\"+pSRV+"\eFac\"+gempresa+"\adj\"+ALLTRIM(pPFE)+ALLTRIM(pnrodcto)
			
			IF DIRECTORY(lceFac_adjs)
				lceFac_adjs=lceFac_adjs+"\*.*"
				lc_adjs=SYS(3)
				DIR &lceFac_adjs TO &lc_adjs
				CREATE CURSOR eFac_adjs(linea CHAR(250))
				SELECT eFac_adjs
				APPEND FROM &lc_adjs SDF FOR ALLTRIM(pPFE)+ALLTRIM(pnrodcto)$ALLTRIM(linea)
				GO TOP 
				SCAN
					lceFac_adjs="\\"+pSRV+"\eFac\"+gempresa+"\adj\"+ALLTRIM(linea)
					WAIT 'Procesando Archivo '+LOWER(lceFac_adjs) WINDOW NOWAIT
					IF FILE(lceFac_adjs)
						oFolder.CopyHere(lceFac_adjs)
					ENDIF
					INKEY(1)
					WAIT CLEAR
				ENDSCAN
			ENDIF
			oFolder = .F.
		ENDIF
		oShell = .F.
	ENDIF
	IF FILE(lceFac_adj) 
		ERASE &lceFac_adj
	ENDIF
	IF FILE(lceFac_Sig) 
		ERASE &lceFac_Sig
	ENDIF
	IF FILE(lceFac_pdf) 
		ERASE &lceFac_pdf
	ENDIF
ENDFUNC

PROCEDURE eFac_INI
	Store "" TO wDOCS,wCUFE,wCUDE,wQRFILE,wLink,eFacImp,CUFE,pNIT,pSRV,pPWD,pCer,pCCo,mNroResol,mfhautoriz,mFvenReso,mConsecIni,mConsecFin,pPFE,pCFE,wTESTSETID
	SELECT 0 
	IF SQLEXEC(gConexEmp,"Select DctoMae from Tipodcto where Origen='FAC' AND TipoDcto=?pTipoDcto ","eFac_Valid") < 0
		WAIT WINDOW NOWAIT wVer+' - '+"ERROR DE CONEXION 0"+pemp
	ENDIF
	SELECT eFac_Valid
	GO TOP
	pTDM=DctoMae
	pPFE=DctoMae
	pEmp="XX"
	pFec=CTOD('')
	SELECT 0 
	IF SQLEXEC(gConexEmp,"Select * from eFac_MTG ","eFac_Valid") < 0
		WAIT WINDOW NOWAIT wVer+' - '+"ERROR DE CONEXION 0"+pemp
	ENDIF
	SELECT eFac_Valid
	GO TOP 
	IF ALLTRIM(EFAC01)=ALLTRIM(gempresa) AND LEN(ALLTRIM(EFAC00)) = 2
		pSRV=ALLTRIM(EFAC02)
		***
		IF !"VFPENCRYPTION.FLL"$SET("Library")
			warchivo='LOCFILE("\\'+pSRV+'\eFac\Obj\vfpencryption.fll")'
			SET LIBRARY TO &warchivo ADDITIVE
		ENDIF
		IF !"FOXBARCODEQR.FXP"$SET("Procedure")
			warchivo="'\\"+pSRV+"\eFac\Obj\FoxBarcodeQR.fxp'"
			SET PROCEDURE TO &warchivo ADDITIVE
		ENDIF
		IF !"CDO2000.FXP"$SET("Procedure")
			warchivo="'\\"+pSRV+"\eFac\Obj\CDO2000.FXP'"
			SET PROCEDURE TO &warchivo ADDITIVE
		ENDIF
		***
		pemp=ALLTRIM(EFAC00)
		pFec=CTOD(EFAC14)
		pNIT=ALLTRIM(SUBSTR(ALLTRIM(EFAC04),1,AT('-',ALLTRIM(EFAC04))-1))
		pSRV=ALLTRIM(EFAC02)
		pPWD=ALLTRIM(eFAC_ScD(EFAC03))
		IF LEN(pPWD)>5 AND SUBSTR(pPWD,1,1) = '+' AND SUBSTR(pPWD,LEN(pPWD),1) = '+'
			pPWD=SUBSTR(pPWD,2,LEN(pPWD)-2)
		ENDIF
		IF LEN(ALLTRIM(pNIT))=8
			pCHR='8'
		ELSE 
			IF LEN(ALLTRIM(pNIT))=10
				pCHR='0'
			ELSE 
				pCHR='9'
			ENDIF
		ENDIF
		pPWD=ALLTRIM(EFAC00)+pCHR+pNIT+pPWD
		pCer=ALLTRIM(EFAC23)
		pCCo=ALLTRIM(EFAC20)
		pRZS=ALLTRIM(EFAC05)
		eFacImp=ALLTRIM(eFacImp)
	ENDIF
	NroDct=VAL(pNroDcto)
	mStrSQLx = "Select * From eFac_Resol Where CodigoCons=?pCodigoConse AND (?NroDct BETWEEN consecini and consereal OR DCTOMAE IN('NC','ND'))"
	If SQLExec(gConexEmp,mStrSQLx,"eFac_Resol")<=0
		oGenerica.Mensajes("No es posible seleccionar los datos de la Resolución")
		Return 0
	Endif
	Select eFac_Resol
	Go Top
	If !Eof()
		mNroResol=Alltrim(eFac_Resol.NroResol)
		mfhautoriz=eFac_Resol.FhAutoriz
		mFvenReso=eFac_Resol.FvenReso
		mConsecIni=Str(eFac_Resol.ConsecIni)
		mConsecFin=Str(eFac_Resol.ConsecFin)
		pPFE=ALLTRIM(eFac_Resol.PREFIJDIAN)
		pCFE=ALLTRIM(eFac_Resol.LLAVEDIAN)
		wTESTSETID=ALLTRIM(eFac_Resol.TESTSETID)
	Else
		pCFE="X"
	Endif
	mNroDctoPrefijo=pPFE+pNroDcto
	IF USED('TRADEMAS')
		SELECT TRADEMAS
		USE
	ENDIF 
	SELECT 0
	mstrsql=" SELECT * FROM eFac_Mas Where Origen='FAC' AND TipoDcto=?pTipoDcto AND NroDcto=?pNroDcto "
	If SQLExec(gConexEmp,mstrsql,"TRADEMAS")<=0
		qmOrigen='FAC'
		qmTipoDcto=pTipoDcto
		qmNroDcto=pNroDcto
		USE qtrademas ALIAS trademas
	ENDif
	Select TRADEMAS
	GO TOP 
	warchivo="'\\"+pSRV+"\eFac\Obj\'"
	SET PATH TO &warchivo ADDITIVE
	RETURN 
ENDPROC

