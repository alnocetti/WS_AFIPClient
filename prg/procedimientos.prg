*******************************
* FUNCION COMPLETAR CON CEROS *
*******************************
FUNCTION STRZERO
PARAMETERS VARI,DIGI
PRIVATE AUX

IF DIGI < 1 .OR. DIGI > 1 + LEN(STR(ABS(VARI)))
   DIGI = LEN(STR(ABS(VARI)))
ENDIF
AUX = SUBSTR(STR(ABS(VARI)), 1 + LEN(STR(ABS(VARI))) - DIGI)
AUX = REPLICATE("0",DIGI - LEN(LTRIM(AUX))) + LTRIM(AUX)
RETURN IIF(VARI < 0, "-" + SUBSTR(AUX,2), AUX)
ENDFUNC


*-- Funcion para autenticar, devuelve el ticket de acceso (reutilizado o nuevo)
FUNCTION Autenticar 
PARAMETERS service
	firma = ""
	token = ""
	expiracion = ""
	ticket = ticketAcceso + "_" + service + ".xml"
	
	ON ERROR DO errhand1
	
	f = FOPEN(ticket)  
	IF f = -1 THEN
		*MESSAGEBOX("no existe TA")
		ta = ""		&& no existe el TA previo
		expiracion = ""
		token = ""
		firma = ""
	ELSE
		ta = FREAD(f, 65535)
		=FCLOSE(f)
	ENDIF
*!*		WSAA = CREATEOBJECT("WSAA") 
	ok = WSAA.AnalizarXml(ta)
	expiracion = WSAA.ObtenerTagXml("expirationTime")
	IF ISNULL(expiracion) THEN
	    solicitar = .T.         					&& solicitud inicial
	ELSE
		solicitar = WSAA.Expirado(expiracion)		&& chequear solicitud previa
		firma = WSAA.ObtenerTagXml("sign")
		token = WSAA.ObtenerTagXml("token")
	ENDIF
	IF solicitar THEn
		
		ta = WSAA.Conectar("", url)
		
		*-- Generar un Ticket de Requerimiento de Acceso (TRA)
		tra = WSAA.CreateTRA(service)

		*-- Generar el mensaje firmado (CMS) 
		cms = WSAA.SignTRA(tra, certificado, clavePrivada) && Cert. Demo
		*-- cms = WSAA.SignTRA(tra, ruta + "homo.crt", ruta + "homo.key") 

		*-- Llamar al web service para autenticar
		ta = WSAA.LoginCMS(cms)

		IF LEN(WSAA.Excepcion) > 0 THEN 
			MESSAGEBOX("No se pudo obtener token y sign WSAA",0+48,"Error")
			STORE .t. TO hayError
			return
		ELSE
			MESSAGEBOX("Conexi�n establecida con �xito!",0+64,"Conexi�n")
		ENDIF
		
		firma = WSAA.ObtenerTagXml("sign")
		token = WSAA.ObtenerTagXml("token")
		expiracion = WSAA.ObtenerTagXml("expirationTime")
		*-- Grabo el ticket de acceso para poder reutilizarlo
		*-- (revisar temas de seguridad y permisos)
		f = FCREATE(ticket)  
		w = FWRITE(f, ta)
		=FCLOSE(f)

	ENDIF
	
	*-- devuelvo el ticket de acceso
	ON ERROR
	RETURN ta
ENDPROC

*-- Procedimiento para manejar errores WSAA
PROCEDURE errhand1
	*--PARAMETER merror, mess, mess1, mprog, mlineno
	
*!*		? WSAA.Excepcion
*!*		? WSAA.Traceback
	*--? WSAA.XmlRequest
	*--? WSAA.XmlResponse

	*-- trato de extraer el codigo de error de afip (1000)
	afiperr = ERROR() -2147221504 
	if afiperr>1000 and afiperr<2000 then
*!*			? 'codigo error afip:',afiperr
	else
		afiperr = 0
	endif
*!*		? 'Error number: ' + LTRIM(STR(ERROR()))
*!*		? 'Error message: ' + MESSAGE()
*!*		? 'Line of code with error: ' + MESSAGE(1)
*!*		? 'Line number of error: ' + LTRIM(STR(LINENO()))
*!*		? 'Program with error: ' + PROGRAM()

	*-- Preguntar: Aceptar o cancelar?
	ch = MESSAGEBOX(WSAA.Excepcion, 0 + 48, "Error al autenticar")
	firma = ""
	token = ""
	
	STORE .t. TO hayError
	return
ENDPROC

PROCEDURE handErrGeneral

		MESSAGEBOX("Ocurrio un error interno",0+16,"Error.")
ENDPROC


*-- Procedimiento para manejar errores WSFE
PROCEDURE errhand2

	MESSAGEBOX("Ocurrio un error interno",0+16,"Error.")
	
	vDebug = WSFE.XmlRequest
	f = FCREATE(rutaArchivos + "xml\xmlResquest_WSFEv1_autorizacion" + ALLTRIM(STR(nic,10)) + ".xml")  
	w = FWRITE(f, vDebug)
	=FCLOSE(f)
	   	
	vDebug = WSFE.XmlResponse
	f = FCREATE(rutaArchivos + "xml\xmlResponse_WSFEv1_autorizacion" + ALLTRIM(STR(nic,10)) + ".xml")  
	w = FWRITE(f, vDebug)
	=FCLOSE(f)
	
	SELECT wsfelres
	replace resestado WITH 0

ENDPROC

*-- Procedimiento para manejar errores WSLPG
PROCEDURE errhand3
	*MESSAGEBOX(loError.message,0+48,"Error")
	
	vDebug = WSLPG.XmlRequest
	f = FCREATE(rutaArchivos + "xml\xmlResquest_WSLPG_autorizacion" + ALLTRIM(STR(nic,10)) + ".xml")  
	w = FWRITE(f, vDebug)
	=FCLOSE(f)
	   	
	vDebug = WSLPG.XmlResponse
	f = FCREATE(rutaArchivos + "xml\xmlResponse_WSLPG_autorizacion" + ALLTRIM(STR(nic,10)) + ".xml")  
	w = FWRITE(f, vDebug)
	=FCLOSE(f)
	
	SELECT wslpgres
	replace resestado WITH 0

ENDPROC

PROCEDURE salir
	STORE .t. TO ending
	
	* cERRAR FORMULARIOS
	LOCAL lni
	FOR m.lnI = _SCREEN.FORMCOUNT TO 1 STEP -1
		_SCREEN.FORMS(m.lnI).RELEASE
	ENDFOR
	
	* CERRAR TABLAS Y DBC
	CLOSE DATABASES all
	
	* LIMPIEZA
	*CLOSE ALL
	CLEAR EVENTS
	SET PROCEDURE TO
	
	*QUIT
	
ENDPROC

PROCEDURE errHandGeneral
	
	MESSAGEBOX(loError.message + CHR(13) + "Linea: " + loError.linecontents,;
				0+48,;
				loError.name + ": " + ALLTRIM(STR(loError.errorno)))
	
	RETURN
ENDPROC


PROCEDURE checkCuit
PARAMETERS vCuit

Xcampo = LEFT(vCuit,10)
vActual = RIGHT(vCuit,1)
Xcoef = "5432765432" 
ret = .T. 
Suma = 0 
FOR X = 1 to 10 
	Suma = Suma + VAL(SUBSTR(XCampo,X,1)) * VAL(SUBSTR(XCoef,X,1)) 
NEXT 

Resto = INT(suma % 11) 
digitoVer = 11 - Resto

DO case
	CASE digitoVer = 11
		digitoVer = 0
	CASE digitoVer = 10
		digitoVer = 9
	OTHERWISE
		digitoVer = digitoVer
ENDCASE
*MESSAGEBOX("Digito verificador: " + STR(digitoVer,1))
IF STR(digitoVer,1) # vActual
	ret = .f.
ELSE
	ret = .t.
ENDIF

RETURN ret
ENDPROC

PROCEDURE eliminarEmpresa
PARAMETERS idSelected
CLOSE databases
SELECT 0
USE &patdbf.empresas.dbf index &patdbf.empresas.cdx ALIAS empresas EXCLUSIVE
SET ORDER to 1
SEEK idSelected
IF FOUND()
	*SET STEP ON
	DELETE
	MESSAGEBOX("Registro eliminado",0+64,"Eliminacion")
	CLOSE DATABASES
	RETURN .t.
ELSE
	MESSAGEBOX("Se produjo un error" ,0+64,"Error")
	CLOSE DATABASES
	RETURN .f.
ENDIF
ENDPROC

PROCEDURE agregarEmpresa
PARAMETERS idEmpresa,cuitempresa,nombreEmpresa

SELECT empresas
APPEND BLANK
replace codigo WITH idEmpresa
replace cuit WITH cuitEmpresa
replace nombre WITH nombreEmpresa
MESSAGEBOX("Empresa agregada correctamente",0+64,"Alta empresa")

ENDPROC

*-- Procedimiento para manejar errores
PROCEDURE errhandCot
	*--PARAMETER merror, mess, mess1, mprog, mlineno

	? 'Error number: ' + LTRIM(STR(ERROR()))
	? 'Error message: ' + MESSAGE()
	? 'Line of code with error: ' + MESSAGE(1)
	? 'Line number of error: ' + LTRIM(STR(LINENO()))
	? 'Program with error: ' + PROGRAM()

	*-- Preguntar: Aceptar o cancelar?
	ch = MESSAGEBOX(MESSAGE(), 5 + 48, "Error:")
	IF ch = 2 && Cancelar
		ON ERROR 
		CLEAR EVENTS
		CLOSE ALL
		RELEASE ALL
		CLEAR ALL
		CANCEL
	ENDIF	
ENDPROC

PROCEDURE genAuxTable
PARAMETERS tableName, tableAux, structureAux, idx, appe
	SELECT 0
	USE &rutaArchivos.&tableName
	COPY STRUCT EXTEND TO &structureAux
	CLOSE DATABASES

	CREATE &tableAux from &structureAux
	CLOSE DATABASES

	SELECT 0
	USE &tableAux 
	INDEX on &idx TO &tableAux 
	USE
	USE &tableAux INDEX &tableAux EXCLUSIVE

	*- Limpio la tabla por si habia alg�n registro anterior con error
	ZAP
	PACK
	
	APPEND FOR &appe from &rutaArchivos.&tableName
	CLOSE DATABASES
ENDPROC

PROCEDURE agregarEmpresa()
	CLOSE DATABASES
	STORE ""	TO certificado
	STORE ""	TO clavePrivada
	STORE "" 	TO url
	STORE "0"	TO cuit
	STORE ""	TO nombre
	STORE ""	TO rutaArchivos
	STORE ""	TO rutaTicket
	STORE .f.	TO homologacion
	STORE "fox2x" TO formato
	DO FORM &patforms._form_parametros_generales
ENDPROC

	