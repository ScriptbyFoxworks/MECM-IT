<#
.Synopsis
   Get-CMPackageFlags
.DESCRIPTION
   This Function will return the PkgFlags of a Package. You can combine it Get-CMPackage through Pipeline or call the Integer-Value
.EXAMPLE
   Get-CMPackage -Name OSD-Scripts -Fast | Get-CMPackageFlags -Verbose
   Get-CMPackageFlags -PkgFlags 50331776 -Verbose 
.REQUIREMENTS
   PowerShell: 5.1.17763.1007
   ConfigMgrCmdLetModule: 5.2002.1083.2000
   ConfigMgr-Console must be installed
   ConfigMgr-Drive must be loaded
#>
Function Get-CMPackageFlags
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [Int]$PkgFlags
)
 
    Begin
    {
        Write-Verbose "Prepare DPLocalityFlag-HashTable"
        # https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/servers/configure/sms_packagebaseclass-server-wmi-class
        $PkgFlagsTable = @{
                            'DO_NOT_ENCRYPT_CONTENT_ON_CLOUD' = 8388608
                            'DO_NOT_DOWNLOAD' = 16777216
                            'PERSIST_IN_CACHE' = 33554432
                            'USE_BINARY_DELTA_REP' = 67108864
                            'NO_PACKAGE' = 268435456
                            'USE_SPECIAL_MIF' = 536870912
                            'DISTRIBUTE_ON_DEMAND' = 1073741824
                          }
        
        Write-Verbose "Results based on HashTable-Keys: $($PkgFlagsTable.Keys)"
    }
    Process
    {
        # Create empty Output-Variable
        [HashTable]$FlagsObject = [ordered]@{}
 
        Write-Verbose "Loop for each Key in HashTable"
        Foreach ($FlagType in $PkgFlagsTable.Keys)
        {
            Write-Verbose "Use Bit-Comparison-Operator to compare Flag: $($FlagType)"
            If (($PkgFlags -band $PkgFlagsTable.$FlagType) -ne 0)
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
 
Get-CMPackage -Name OSD-Scripts -Fast | Get-CMPackageFlags -Verbose
