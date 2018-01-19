# requires -version 2
<#
.SYNOPSIS
	Script de envío de archivos de Trazabilidad a Fobesa
	
.DESCRIPTION
	Script de envío de archivos de Trazabilidad a Fobesa
	
.INPUTS
	None
	
.OUTPUTS
	Función Write-Log reemplaza llamadas a Write-Host
	Write-Host se usa únicamente para las excepciones en conjunto con la función Write-Log
		
.NOTES
	Version:		1.0
	Author:			Santiago Platero
	Creation Date:	19/01/2018
	Purpose/Change: SScript de envío de archivos de Trazabilidad a Fobesa
	
.EXAMPLE
	>powershell -command ".'<absolute path>\fobesa-traza.ps1'"
#>

#---------------------------------------------------------[Inicializaciones]--------------------------------------------------------

# Inicializaciones de variables
$fileSource = "\\ar-san-mtv2\QAD\traza\IN\*"
$fileSourceCopied = "\\ar-san-mtv2\QAD\traza\OUT\"
$fileDestination = "/interfaces/sistemasmv/entrada/*"
$dateFormat = "dd-MMM-yyyy HH:mm:ss"

#----------------------------------------------------------[Declaraciones]----------------------------------------------------------

# Información del script
$scriptVersion = "1.0"
$scriptName = $MyInvocation.MyCommand.Name

# Información de archivos de logs
$logPath = "C:\logs"
$logName = "$($scriptName).log"
$logFile = Join-Path -Path $logPath -ChildPath $logName

#-----------------------------------------------------------[Funciones]------------------------------------------------------------

#Función para hacer algo (?) de logueo
Function Write-Log
{
	Param ([string]$logstring)	
	Add-Content $logFile -value $logstring
}

Function Write-Exception
{
	Write-Host "[$(Get-Date -format $($dateFormat))] ERROR: $($_.Exception.Message)"
	Write-Log "[$(Get-Date -format $($dateFormat))] ERROR: $($_.Exception.Message)"
	Write-Log "[$(Get-Date -format $($dateFormat))] FIN DE EJECUCION DE $($scriptName)"
	Write-Log " "
	exit 1
}

#-----------------------------------------------------------[Ejecución]------------------------------------------------------------

# Primer control de errores: falta DDL, errores del servidor remoto, etc.
Write-Log "[$(Get-Date -format $($dateFormat))] INICIO DE EJECUCION DE $($scriptName)"
try
{
	# Carga de DLL de WinSCP .NET
	Add-Type -Path "c:\git\WinSCPnet.dll"

	# Configuración de opciones de sesión
	$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
		Protocol = [WinSCP.Protocol]::Sftp
		HostName = "201.216.255.169"
		PortNumber = 20022
		UserName = "sistemasmv"
		SshHostKeyFingerprint = "ssh-rsa 2048 d0:cb:1f:b6:7a:07:54:1f:e7:40:28:09:d4:f9:04:66"
		SshPrivateKeyPath = "c:\git\fobesa.ppk"
	}

	$session = New-Object WinSCP.Session
	# Segundo control de errores: falta archivo, ruta incorrecta, errores de transferencia, etc.
	try
	{
		# Conexión y generamos log
		$session.Open($sessionOptions)
		Write-Log "[$(Get-Date -format $($dateFormat))] Conectando a $($sessionOptions.UserName)@$($sessionOptions.HostName):$($sessionOptions.PortNumber)"
	
		# Opciones de transferencia
		$transferOptions = New-Object WinSCP.TransferOptions
			
		# Envío de archivos MTV
		$transferFiles = $session.PutFiles($fileSource, $fileDestination)
			
		# Arrojar cualquier error
		$transferFiles.Check()
	
		# Loopeamos por cada archivo que se transfiera
		foreach ($transfer in $transferFiles.Transfers)
		{
			$file = $transfer.FileName
		}
		# Antes de mandar al log, verificamos que la variable no sea nula
		if (!$file)
		{
			Write-Log "[$(Get-Date -format $($dateFormat))] Ningún archivo fue encontrado/transferido"
		}
		else
		{
			Write-Log "[$(Get-Date -format $($dateFormat))] Transferencia de $($transfer.FileName) exitosa"
			Move-Item $transfer.FileName $fileSourceCopied
		}
	}
	# Impresión en caso de error en el segundo control
	catch
	{
		Write-Exception
	}
	finally
	{
		# Desconexión, limpieza
		$session.Dispose()
	}
	Write-Log "[$(Get-Date -format $($dateFormat))] FIN DE EJECUCION DE $($scriptName)"
	Write-Log " "
	exit 0
}
# Impresión en caso de error en el primer control
catch 
{
	Write-Exception
}
