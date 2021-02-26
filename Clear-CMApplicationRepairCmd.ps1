<#
.Synopsis
   Clear-CMApplicationRepairCmd
.DESCRIPTION
   This Function will get the Serialized CMApplication-Object and clear the Property RepairCommandline for each DeploymentType.
.EXAMPLE
   Clear-CMApplicationRepairCmd -CMApplicationName 'CMTrace' -Verbose
.REMARKS
   Configuration Manager Cmdlet Libary must be loaded
#>
Function Clear-CMApplicationRepairCmd
{
Param
(
    [Parameter(Mandatory=$true)]
    [String]$CMApplicationName
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

        Write-Verbose "Enum each Deployment-Type to clear the RepairCmdline"
        For ($i; $i -le ($DTCount -1); $i++)
        {
            Write-Verbose "Modify DeploymentType-Title: $($CMAppSerialized.DeploymentTypes[$i].Title)"
            $CMAppSerialized.DeploymentTypes[$i].Installer.RepairCommandLine = ""
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

Clear-CMApplicationRepairCmd -CMApplicationName 'CMPivot' -Verbose
