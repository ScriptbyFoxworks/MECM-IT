<#
.Synopsis
   Get-CMDPLocalityFlags
.DESCRIPTION
   This Function will return the DPLocalityFlags of an Assignment. You can combine it Get-CMApplicationDeployment or Get-CMSoftwareUpdateDeployment
   through Pipeline or call the Integer-Value
.EXAMPLE
   Get-CMSoftwareUpdateDeployment -DeploymentId '{e0d9ba7b-08ab-4d70-8fa6-94bebdee885f}' | Get-CMDPLocalityFlags -Verbose
   Get-CMApplicationDeployment -DeploymentId '{9F5416D9-9997-44DC-83DA-AC1CA052186A}' | Get-CMDPLocalityFlags -Verbose
.REQUIREMENTS
   PowerShell: 5.1.17763.1007
   ConfigMgrCmdLetModule: 5.2002.1083.2000
   ConfigMgr-Console must be installed
   ConfigMgr-Drive must be loaded
#>
Function Get-CMDPLocalityFlags
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [Int]$DPLocality
)
 
    Begin
    {
        Write-Verbose "Prepare DPLocalityFlag-HashTable"
        # https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/compliance/sms_ciassignmentbaseclass-server-wmi-class
        $DPFlagsTable = @{
                           'DP_DOWNLOAD_FROM_LOCAL' = 16
                           'DP_DOWNLOAD_FROM_REMOTE' = 64
                           'DP_NO_FALLBACK_UNPROTECTED' = 131072
                           'DP_ALLOW_WUMU' = 262144
                           'DP_ALLOW_METERED_NETWORK' = 524288
                           }
        
        Write-Verbose "Results based on HashTable-Keys: $($DPFlagsTable.Keys)"
    }
    Process
    {
        # Create empty Output-Variable
        [HashTable]$FlagsObject = [ordered]@{}
 
        Write-Verbose "Loop for each Key in HashTable"
        Foreach ($FlagType in $DPFlagsTable.Keys)
        {
            Write-Verbose "Use Bit-Comparison-Operator to compare Flag: $($FlagType)"
            If (($DPLocality -band $DPFlagsTable.$FlagType) -ne 0)
            {
                Write-Verbose "Match Value found - add $($FlagType) to Output-Variable"
                $FlagsObject.Add($FlagType,$True)
            }
            Else
            {
                Write-Verbose "Match Value not found - add $($FlagType) to Output-Variable"
                $FlagsObject.Add($FlagType,$False)
            }
        }
    }
    End
    {
        Write-Verbose "Return the Result"
        Return $FlagsObject
    }
}
 
Get-CMSoftwareUpdateDeployment -DeploymentId '{e0d9ba7b-08ab-4d70-8fa6-94bebdee885f}' | Get-CMDPLocalityFlags -Verbose
Get-CMApplicationDeployment -DeploymentId '{9F5416D9-9997-44DC-83DA-AC1CA052186A}' | Get-CMDPLocalityFlags -Verbose


