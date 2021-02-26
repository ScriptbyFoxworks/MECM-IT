<#
.Synopsis
   Set-CMApplicationRepairCmd
.DESCRIPTION
   This Function will get the Serialized CMApplication-Object and modify the Property RepairCommandline
.EXAMPLE
   Set-CMApplicationRepairCmd -CMApplicationName 'CMTrace' -RepairCmdLine "cmd.exe /c Test by PS" -Verbose
.REMARKS
   Configuration Manager Cmdlet Libary must be loaded
#>
Function Set-CMApplicationRepairCmd
{
Param
(
    [Parameter(Mandatory=$true)]
    [String]$CMApplicationName,
    [Parameter(Mandatory=$true)]
    [String]$RepairCmdLine
)
    Try
    {
    # Get Appliation
    Write-Verbose "Use ConfigMgr-Cmdlet Get-CMApplication against AppName: $($CMApplicationName)"
    $CMApp = Get-CMApplication -Name $($CMApplicationName)

    # Convert Application to Serialized Object
    Write-Verbose "Create Seralized CM-Application-Object"
    $CMAppSerialized = ConvertTo-CMApplication -InputObject $CMApp

    # Modify Object to you desire
    Write-Verbose "Create Deployment-Type-Counter"
    [Int]$i = 0
    $DTCount = $CMAppSerialized.DeploymentTypes.Count

        Write-Verbose "Enum each Deployment-Type to add the RepairCmdline"
        For ($i; $i -le ($DTCount -1); $i++)
        {
            Write-Verbose "Modify DeploymentType-Title: $($CMAppSerialized.DeploymentTypes[$i].Title)"
            $CMAppSerialized.DeploymentTypes[$i].Installer.RepairCommandLine = $($RepairCmdLine)
        }
        
    # Prepare Object to convert it back as Application - Commit the change with Put
    Write-Verbose "Prepare new CM-Application-Object and Put change"
    $objCMApp = ConvertFrom-CMApplication -InputObject $CMAppSerialized
    $objCMApp.Put()

    Return "Successfully applied changes"

    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
    } 
}

Set-CMApplicationRepairCmd -CMApplicationName 'CMPivot' -RepairCmdLine "cmd.exe /c Test by PS" -Verbose