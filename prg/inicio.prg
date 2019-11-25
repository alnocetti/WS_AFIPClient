_Screen.WindowState=2
Close DataBases
Clear Screen
APPLICATION.VISIBLE = .f.

SET DELETED ON
SET CENTURY ON
SET DATE FRENCH
SET CPDIALOG OFF 
SET SAFETY OFF 
SET TALK OFF 
SET EXCLUSIVE OFF
SET RESOURCE OFF
SET RESOURCE TO

PUBLIC certificado, clavePrivada, url, cuit, nombre, rutaArchivos, expiracion, homologacion, regEmpresa, esAlta, formato
PUBLIC firma,token,rutaTicket,ta,tra,cms,ticketAcceso
PUBLIC patforms,patprg,patdbf,patimg
PUBLIC actividades, fldrMain, hayError, esPrimeraVez
PUBLIC WSAA, WSFE, WSLPG, Padron, ending
PUBLIC esGrupoVeneroni

WSAA = CREATEOBJECT("WSAA") 
WSFE = CREATEOBJECT("WSFEv1")
WSLPG = CREATEOBJECT("WSLPG")

STORE justpath(sys(16, 0)) TO fldrMain
STORE "forms\" TO patforms
STORE "prg\" TO patprg
STORE "dbf\" TO patdbf
STORE "img\" TO patimg
STORE "" TO firma, token, ta, cms, tra
STORE .f. TO homologacion, principal, hayError,esPrimeraVez,ending

esGrupoVeneroni = .f.

SET PROCEDURE TO &patprg.procedimientos

SELECT 1
USE &patdbf.parametros INDEX &patdbf.parametros.cdx exclusive ALIAS parametros
IF RECCOUNT() = 0
	OP = MESSAGEBOX("Es su primer ingreso... vamos a dar de alta una empresa",1+64,"Primer ingreso")	
	IF OP = 1
		CLOSE DATABASES
		STORE .t.	TO esPrimeraVez
		STORE ""	TO certificado
		STORE ""	TO clavePrivada
		STORE "" 	TO url
		STORE ""	TO cuit
		STORE ""	TO nombre
		STORE ""	TO rutaArchivos
		STORE ""	TO rutaTicket
		STORE .f.	TO homologacion
		STORE "fox2x" TO formato
		DO FORM &patforms._form_principal
		DO FORM &patforms._form_parametros_generales
	ELSE
		CANCEL EVENTS
		CLEAR WINDOWS
		CLOSE DATABASES
		CLOSE ALL
		CLEAR ALL
		QUIT
	ENDIF
ELSE
	DO FORM &patforms._form_login.scx
ENDIF
READ EVENTS
