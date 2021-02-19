<#
.Synopsis
   Invoke ConfigMgr Data Discovery Record
.DESCRIPTION
   This example Code will initialize a DDR through the Messaging.dll - the Object discovered will be returned which can be browsed.
.EXAMPLE
   Invoke-CMDataDiscoveryRecord -Verbose
.Requirements
   Elevated Permissions
   MECM 2006 Clients and higher
#>
[CmdletBinding()]
Param()

### Functions 
Function Load-CMMessagingDLL 
{
    [CmdLetBinding()]
    Param
    (
        [Parameter(Mandatory = $True)]
        [String]$PathMessageDLL    
    )

    Write-Verbose "Path to Messageing-DLL: $($PathMessageDLL)"

    Try {
        Write-Verbose "Validate-Parameter-Path $($PathMessageDLL)"

        If ((Test-Path -Path $PathMessageDLL) -and (Get-Process -Name CcmExec).Id -ge 1) {
            Write-Verbose "Verification-Check-Success continue to Load the DLL"

            import-module $PathMessageDLL #C:\Temp\Microsoft.ConfigurationManagement.Messaging.dll
            Return "Success"
        }
        Else {
            Write-Verbose "Unable to find CCM-Messaging-DLL"
            Return "Failure"
        }
    }
    Catch {
        Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Error "Exception Message: $($_.Exception.Message)"
        Write-Error "Exception Stack: $($_.ScriptStackTrace)"
    }
}

Function Get-CMMessagingParams
{
[CmdletBinding()]
Param()

    Begin
    {
        Write-Verbose "Start Gather CM-Messaging-Params:"
        Try
        {
            
            [String]$SiteCode = ([wmiclass]"ROOT\ccm:SMS_Client").GetAssignedSite().sSiteCode
            [int]$httpPort = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Name 'HttpPort').HttpPort
            [int]$httpsPort = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Name 'HttpsPort').HttpsPort
            [String]$currentMP = (Get-WmiObject -class SMS_Authority -Namespace root\ccm).CurrentManagementPoint
            [String]$ClientID = ([wmi]"ROOT\ccm:CCM_Client=@").ClientId
            [String]$CertThumbprint = ([wmi]"ROOT\ccm:CCM_ClientIdentificationInformation=@").ReservedString1
            
        }
        Catch
        {
            Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
            Write-Error "Exception Message: $($_.Exception.Message)"
            Write-Error "Exception Stack: $($_.ScriptStackTrace)"

        }
    }
    Process
    {
        Try
        {
            Write-Verbose "Process-Cert-Type and add gathered Information to a HashTable"
            If ((Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Thumbprint -eq $CertThumbprint}) -ne $null)
            {
                Write-Verbose "Found Thumbprint: $($CertThumbprint) in Personal-Store"
                $CertType = 'PKI'
            }
            ElseIf ((Get-ChildItem Cert:\LocalMachine\SMS | Where-Object {$_.Thumbprint -eq $CertThumbprint}) -ne $null)
            {
                Write-Verbose "Found Thumbprint: $($CertThumbprint) in SMS-Store"
                $CertType = 'SelfSigned'
            }
            Else
            {
                Write-Verbose "The Thumbpring: $($CertThumbprint) was not found in My- or SMS-Store - this is fishi!!!"
                $CertType = $null
            }

            Write-Verbose "Switch/Select Case Statement"
            Switch ($CertType)
            {
                'PKI' {$cert = [Microsoft.ConfigurationManagement.Messaging.Framework.MessageCertificateX509File]::new('My', $CertThumbprint)}
                'SelfSigned' {$cert = [Microsoft.ConfigurationManagement.Messaging.Framework.MessageCertificateX509File]::new('SMS', $CertThumbprint)}
            }

            Write-Verbose "Create the HashTable and populate Information"
            [System.Collections.Hashtable]$CMParamTable =[ordered] @{}

            $CMParamTable.Add('SiteCode',$SiteCode)
            $CMParamTable.Add('SMSID',$ClientID)
            $CMParamTable.Add('Hostname',$currentMP)
            $CMParamTable.Add('Certificate',$cert)
            $CMParamTable.Add('HttpPort',$httpPort)
            $CMParamTable.Add('HttpsPort',$httpsPort)
        
        }
        Catch
        {
            Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
            Write-Error "Exception Message: $($_.Exception.Message)"
            Write-Error "Exception Stack: $($_.ScriptStackTrace)"
        }
    }
    End
    {
        Write-Verbose "Return the HashTable-Object"
        Return $CMParamTable
    }
}

Function Invoke-CMDataDiscoveryMessage
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [System.Collections.Hashtable]$CMMsgParams
)

    Begin
    {
        Try
        {        
            Write-Verbose "Create CCM-Message-Sender-Object"
            $IMessageSender = [Microsoft.ConfigurationManagement.Messaging.Sender.Ccm.CcmSender]::new()

            Write-Verbose "Create ConfigMgrDataDiscoveryRecordMessage-Instance"
            $req = [Microsoft.ConfigurationManagement.Messaging.Messages.ConfigMgrDataDiscoveryRecordMessage]::new()
        }
        Catch
        {
            Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
            Write-Error "Exception Message: $($_.Exception.Message)"
            Write-Error "Exception Stack: $($_.ScriptStackTrace)"
        }   
    }

    Process
    {
        Try
        {
    
            Write-Verbose "Fill up Message-Properties"
            $req.SiteCode = $CMMsgParams.SiteCode
            $req.SmsId = $CMMsgParams.SMSID
            $req.Settings.HostName = $CMMsgParams.Hostname
            $req.Settings.HttpsPort = $CMMsgParams.HttpsPort
            $req.Settings.HttpPort = $CMMsgParams.HttpPort
            $req.AddCertificateToMessage($CMMsgParams.Certificate, 'All') # not required with self-signed cert
            $req.Discover()

            Write-Verbose "Send DDR-Message to the MP - look at the MP_DDR.log at: $($CMMsgParams.Hostname)"
            $req.SendMessage($IMessageSender)
        }
        Catch
        {
            Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
            Write-Error "Exception Message: $($_.Exception.Message)"
            Write-Error "Exception Stack: $($_.ScriptStackTrace)"
        }
    }
    End
    {
        Write-Verbose "Return the DDR-Instance-Object"
        Return $req
    }
}

### Main Actions

Try
{
    $CCMInstDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties' -Name 'Local SMS Path').'Local SMS Path'

    Load-CMMessagingDLL -PathMessageDLL (Join-Path -Path $CCMInstDir -ChildPath 'Microsoft.ConfigurationManagement.Messaging.dll') -Verbose
    Load-CMMessagingDLL -PathMessageDLL (Join-Path -Path $CCMInstDir -ChildPath 'Microsoft.ConfigurationManagement.Security.Cryptography.dll') -Verbose

    # Get CM-Parameters
    $CMMessagingParameters = Get-CMMessagingParams

    # Run DDR-Object
    $DDRObj = Invoke-CMDataDiscoveryMessage -CMMsgParams $CMMessagingParameters -Verbose
    $DDRObj
}
Catch
{
    Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Error "Exception Message: $($_.Exception.Message)"
    Write-Error "Exception Stack: $($_.ScriptStackTrace)"
}