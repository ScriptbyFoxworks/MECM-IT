<#
.Synopsis
   Get-CMContentLocationRequest
.DESCRIPTION
   This Script is using the CM-Messaging-Dll to get the Content-Location-Records. The Output is a simple HashTable - containing the Name, ADSite, IPSubnet, DPType
   We need two Parameters the PackageID and the StoredPkgVersion (SQL: Select Name, PkgID, StoredPkgVersion from DBO.SMSPackages)
   Another possiblity is to use the Content_UniqueID SQL:(Select PkgID, Content_UniqueID, ContentVersion from CI_ContentPackages) for SuperPeers in case of Applications
.EXAMPLE
   .\Get-CMContentLocationRequest.ps1 -PackageID UID:Content_fa6834e5-e4e4-4da2-969c-9a758db1a6c4 -PackageIDVersion 1 -Verbose
   .\Get-CMContentLocationRequest.ps1 -PackageID FOX0000D -PackageIDVersion 34 -Verbose
.REQUIREMENTS
   Microsoft Endpoint Configuration Manager 2006 Client installed
   The Script must run evaluated
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [String]$PackageID,
    [Parameter(Mandatory=$true)]
    [Int]$PackageIDVersion
)

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
            [Int]$HttpState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM' -Name 'HttpsState').HttpsState
            
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

            Write-Verbose "Verify SSLStates to choose correct HTTP-Mode-Object"
            If (($HttpState | Get-SslStateFlag).NativeMode -eq $true)
            {
                Write-Verbose "Client is running in NativeMode create the according Object"
                $httpModeType = [Microsoft.ConfigurationManagement.Messaging.Framework.MessageSecurityMode]::HttpsMode
            }
            Else
            {
                Write-Verbose "Client is running in MixedMode"
                $httpModeType = [Microsoft.ConfigurationManagement.Messaging.Framework.MessageSecurityMode]::HttpMode
            }

            Write-Verbose "Create the HashTable and populate Information"
            [System.Collections.Hashtable]$CMParamTable =[ordered] @{}

            $CMParamTable.Add('SiteCode',$SiteCode)
            $CMParamTable.Add('SMSID',$ClientID)
            $CMParamTable.Add('Hostname',$currentMP)
            $CMParamTable.Add('Certificate',$cert)
            $CMParamTable.Add('HttpPort',$httpPort)
            $CMParamTable.Add('HttpsPort',$httpsPort)
            $CMParamTable.Add('HttpModeType', $httpModeType)
        
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

Function Get-SslStateFlag
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [Int]$SslStateFlag
)

    Begin
    {
        # Prepare FlagOffer-HashTable
        $SslStateFlagsTable = @{
                                'AllowHttpFallback' = 64
                                'AllowPkiCertRegistration' = 256 
                                'ClientAuthEnabled' = 4
                                'ClientAuthRequired' = 8
                                'Disabled' = 0
                                'EnableClientCrlChecking' = 32
                                'Enabled' = 1
                                'HybridMode' = 159
                                'MixedMode' = 0
                                'NativeMode' = 31
                                'Required' = 2
                                'Use128BitEncrption' = 16
                                'UseSslWhenEnabled' = 128 
                               }
        
    }
    Process
    {
        # Create empty Output-Variable
        [HashTable]$FlagsObject = [ordered]@{}
        
        # Loop for each Key in HashTable
        Foreach ($FlagType in $SslStateFlagsTable.Keys)
        {
            # Use Bit-Comparison-Operator to compare Flag: $($FlagType)
            If (($SslStateFlag -band $SslStateFlagsTable.$FlagType) -ne 0)
            {
                # Match Value found - add $($FlagType) to Output-Variable
                #$OutPut += $FlagType
                $FlagInput = @{
                                'FlagType' = $FlagType
                                'Activated' = $True
                              }
                # Add Information to the Final HashTable-Result
                $FlagsObject.Add($FlagType,$True)
            }
        }
    }
    End
    {
        #if ([string]::IsNullOrEmpty($FlagsObject.Keys)) { $FlagsObject.Add('MixedMode', $True) }
        #if ($detailed) { Write-Log "SSLState Flags returned: $($FlagsObject.Keys -join ', ')" }
        Return $FlagsObject
    }
}

Function Get-CMContentLocationReply
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [System.Collections.Hashtable]$CMMsgParams,
    [Parameter(Mandatory=$True)]
    [String]$PackageID,
    [Parameter(Mandatory=$True)]
    [Int]$PackageVersion
)

    Begin
    {
        Try
        {        
            Write-Verbose "Create CCM-Message-Sender-Object"
            $IMessageSender = [Microsoft.ConfigurationManagement.Messaging.Sender.Http.HttpSender]::new()

            Write-Verbose "Create ConfigMgrContentLocationRequest-Instance"
            $req = [Microsoft.ConfigurationManagement.Messaging.Messages.ConfigMgrContentLocationRequest]::new()

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
            $req.Discover()
            $req.SiteCode = $CMMsgParams.SiteCode
            $req.SmsId = $CMMsgParams.SMSID
            $req.Settings.HostName = $CMMsgParams.Hostname
            $req.Settings.HttpsPort = $CMMsgParams.HttpsPort
            $req.Settings.HttpPort = $CMMsgParams.HttpPort
            $req.Settings.SecurityMode = $CMMsgParams.HttpModeType
            $req.AddCertificateToMessage($CMMsgParams.Certificate, 'All') # not required with self-signed cert
            $req.LocationRequest.Package.PackageId = $PackageID
            $req.LocationRequest.Package.Version = $PackageVersion
            $req.LocationRequest.ContentLocationInfo.AllowSuperPeer = 1
            
            $CMReply = $req.SendMessage($IMessageSender)
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
        Return $CMReply
    }
}

### Main Actions

Try
{
    $CCMInstDir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\SMS\Client\Configuration\Client Properties' -Name 'Local SMS Path').'Local SMS Path'

    Load-CMMessagingDLL -PathMessageDLL (Join-Path -Path $CCMInstDir -ChildPath 'Microsoft.ConfigurationManagement.Messaging.dll')
    Load-CMMessagingDLL -PathMessageDLL (Join-Path -Path $CCMInstDir -ChildPath 'Microsoft.ConfigurationManagement.Security.Cryptography.dll')

    # Get CM-Parameters
    $CMMessagingParameters = Get-CMMessagingParams
    $CMMessagingParameters

    # Run CMContentLocacationReqeust-Object
    $CMReplyObj = Get-CMContentLocationReply -CMMsgParams $CMMessagingParameters -PackageID $PackageID -PackageVersion $PackageIDVersion
    $CMReplyObj

    If ($CMReplyObj.SenderType -eq 'Reply')
    {
        [Int]$i = 0
        [Int]$RecordsCount = $CMReplyObj.LocationReply.Sites.Sites.Count
        $LocationRecords = [System.Collections.ArrayList]::new()

        Write-Verbose "Return LocationRecords:"

        For ($i; $i -le ($RecordsCount -1); $i++)
        {
            If (($CMReplyObj.LocationReply.Sites.Sites[$i].LocationRecords[0].LocationRecords) -ne '')
            {
                [System.Collections.HashTable]$Locations = [Ordered]@{}
                $Locations.Add('Source',$CMReplyObj.LocationReply.Sites.Sites[$i].LocationRecords[0].LocationRecords)
                $Locations.Add('DPType',$CMReplyObj.LocationReply.Sites.Sites[$i].LocationRecords[0].LocationRecords.DPType)
                $Locations.Add('ADSite',$CMReplyObj.LocationReply.Sites.Sites[$i].LocationRecords[0].LocationRecords.ADSite.ADSiteName)
                $Locations.Add('SubNet',$CMReplyObj.LocationReply.Sites.Sites[$i].LocationRecords[0].LocationRecords.IPSubnets.IPSubnets.SubnetAddress)

                $ContentLocationTable =  New-Object PSObject -Property $Locations
                [void]$LocationRecords.Add($ContentLocationTable)
            }
        }

        Return $LocationRecords
    }

}
Catch
{
    Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
    Write-Error "Exception Message: $($_.Exception.Message)"
    Write-Error "Exception Stack: $($_.ScriptStackTrace)"
}