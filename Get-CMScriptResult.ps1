<#
.Synopsis
   Get-CMScriptResult
.DESCRIPTION
   This Function will get the Result of RunScript-Operation. 
.EXAMPLE
   $ScriptResults = Get-CMScriptResult -OperationID 16836564 -Verbose -DebugMode
   $ScriptResults | Out-GridView
.REMARKS
   Configuration Manager Cmdlet Libary must be loaded
#>
Function Get-CMScriptResult
{
[CmdLetBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [Int]$OperationID,
    [Switch]$DebugMode
)
 
Switch ($DebugMode)
{
    $true {
    # Set Global Variables & DebugMode
    $Global:VerbosePreference = "Continue" 
    $Global:DebugPreference = "Continue" 
    $Global:CMPSDebugLogging = $true
    }
}
 
    Try
    {
        Write-Verbose "Execute WMI-Query to get the Script-TaskId for the Operation $($OperationID)"
        $ScriptTask = Invoke-CMWmiQuery -Query "Select TaskID from SMS_ScriptsExecutionTask where ClientOperationID='$($OperationID)'"
        Write-Verbose "Get the following TaskID: $($ScriptTask.TaskID)"
 
        Write-Verbose "Get all Results form the TaskID $($ScriptTask.TaskID)"
        $ScriptStatus = Invoke-CMWmiQuery -Query "Select ResourceID, ScriptExecutionState, ScriptExitCode, ScriptOutPut from SMS_ScriptsExecutionStatus where TaskID ='$($ScriptTask.TaskID)'"
        Write-Verbose "Got the Output for ResourceIDs: $($ScriptStatus.ResourceID)"
 
        Write-Verbose "Return the Object for later processing"
        Return $ScriptStatus
    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
    }
}
 
$ScriptResults = Get-CMScriptResult -OperationID 16836564 -Verbose -DebugMode
$ScriptResults | Out-GridView 

