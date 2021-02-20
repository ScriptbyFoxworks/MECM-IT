<#
.Synopsis
   Get-CMProgramFlags
.DESCRIPTION
   This Function will return the PkgFlags of a Program. You can combine it Get-CMProgram through Pipeline or call the Integer-Value
.EXAMPLE
   Get-CMProgram -PackageId FOX0007B | Get-CMProgramFlags -Verbose
   Get-CMProgramFlags -ProgramFlags 2282800128 -Verbose 
.REQUIREMENTS
   PowerShell: 5.1.17763.1007
   ConfigMgrCmdLetModule: 5.2002.1083.2000
   ConfigMgr-Console must be installed
   ConfigMgr-Drive must be loaded
#>
Function Get-CMProgramFlags
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [Int64]$ProgramFlags
)

    Begin
    {
        Write-Verbose "Prepare DPLocalityFlag-HashTable"
        # https://docs.microsoft.com/en-us/mem/configmgr/develop/reference/core/servers/configure/sms_program-server-wmi-class
        $ProgramFlagsTable = @{
                           'AUTHORIZED_DYNAMIC_INSTALL' = 1
                           'USECUSTOMPROGRESSMSG' = 2
                           'DEFAULT_PROGRAM' = 16
                           'DISABLEMOMALERTONRUNNING' = 32
                           'MOMALERTONFAIL' = 64
                           'RUN_DEPENDANT_ALWAYS' = 128
                           'WINDOWS_CE' = 256
                           'COUNTDOWN' = 1024
                           'DISABLED' = 4096
                           'UNATTENDED' = 8192
                           'USERCONTEXT' = 16384
                           'ADMINRIGHTS' = 32768
                           'EVERYUSER' = 65536
                           'NOUSERLOGGEDIN' = 131072
                           'OKTOQUIT' = 262144
                           'OKTOREBOOT' = 524288
                           'USEUNCPATH' = 1048576
                           'PERSISTCONNECTION' = 2097152
                           'RUNMINIMIZED' = 4194304
                           'RUNMAXIMIZED' = 8388608
                           'HIDEWINDOW' = 16777216
                           'OKTOLOGOFF' = 33554432
                           'ANY_PLATFORM' = 134217728
                           'SUPPORT_UNINSTALL' = 536870912
                           'SHOW_IN_ARP' = 2147483648
                           }
        
        Write-Verbose "Results based on HashTable-Keys: $($DPFlagsTable.Keys)"
    }
    Process
    {
        # Create empty Output-Variable
        [HashTable]$FlagsObject = [ordered]@{}

        Write-Verbose "Loop for each Key in HashTable"
        Foreach ($FlagType in $ProgramFlagsTable.Keys)
        {
            Write-Verbose "Use Bit-Comparison-Operator to compare Flag: $($FlagType)"
            If (($ProgramFlags -band $ProgramFlagsTable.$FlagType) -ne 0)
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

Get-CMProgram -PackageId FOX0007B | Get-CMProgramFlags -Verbose
Get-CMProgramFlags -ProgramFlags 2282800128 -Verbose