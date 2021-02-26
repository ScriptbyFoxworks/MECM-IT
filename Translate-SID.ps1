<#
.Synopsis
   Translate-SID
.DESCRIPTION
   Help-Function to Translate the SID-Guid in a human readable format. The SID can be User or ComputerObject.
.EXAMPLE
   Translate-SID -SID S-1-5-21-2754794008-54600883-1365009979-1106 -Verbose
#>
Function Translate-SID
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [String]$SID
)
    Try
    {
        Write-Verbose "Create System.Security Object for the Identifier: $($SID)"
        $objSID = [System.Security.Principal.SecurityIdentifier]::new($($SID))
        $objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
        
        Write-Verbose "Return Human-Readable NT Account $($objUser.Value)"
        Return $objUser.Value
    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
    }
}

Translate-SID -SID S-1-5-21-2754794008-54600883-1365009979-1106 -Verbose
