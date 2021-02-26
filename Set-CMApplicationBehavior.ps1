<#
.Synopsis
   Set-CMApplicationInstallBehavior
.DESCRIPTION
   This Function will help you to set or to clear the Process Check List (Install Behavior) for DeploymentTypes
.EXAMPLE
   Set-ApplicationInstallBehavior -ApplicationName CMTrace -Executable Dummy3.exe -ExeInfo 'Dummy App3' -Verbose
.EXAMPLE
   Set-ApplicationInstallBehavior -ApplicationName CMTrace -Clear -Verbose
.REQUIREMENT
   Installed ConfigMgr-Console, ConfigMgr-Drive must be loaded
.REMARKS
    Powershell: 5.1.14393.2189
    ConfigMgrCmdlet: 5.1802.1082.1800
#>
Function Set-CMApplicationInstallBehavior
{
[CmdLetBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [String]$ApplicationName,
    [Parameter(Mandatory=$false)]
    [ValidatePattern("^.*\.(exe|EXE)$")]
    [String]$Executable,
    [Parameter(Mandatory=$false)]
    [String]$ExeInfo,
    [Switch]$Clear
)

Write-Verbose "ApplicationName = $($ApplicationName)"
Write-Verbose "Executable = $($Executable)"
Write-Verbose "ExeInfo = $($ExeInfo)"
Write-Verbose "ClearOption = $($Clear)"

Switch($Clear)
{
    $true {
            Try
            {
                Write-Verbose "Get Application Information $($ApplicationName)"
                $App = Get-CMApplication -Name $ApplicationName

                Write-Verbose "Transform Information to SDK-Model"
                $AppInfo = ConvertTo-CMApplication -InputObject $App

                Write-Verbose "Get DeploymentType-Count - used by FOR-Call"
                [Int]$i = 0
                $DTCount = $AppInfo.DeploymentTypes.Count

                Write-Verbose "Clear Process List in $($DTCount) DeploymentType(s)"
                For ($i; $i -le ($DTCount -1); $i++)
                {
                    $AppInfo.DeploymentTypes[$i].Installer.InstallProcessDetection.ProcessList.Clear()
                }

                Write-Verbose "Application-SDK-Object prepared/set - Apply the Change"
                $objApp = ConvertFrom-CMApplication -InputObject $AppInfo
                $objApp.Put()
                Return "Success"
                    
            }
            Catch
            {
                Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
                Write-Verbose "Exception Message: $($_.Exception.Message)"
                Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
                Return "Failure"
            }
          ;Break}
}

    Try
    {
        # Build Application Management Objects
        Write-Verbose "Create SDK-Objects for ProcessInformation & Displayname"
        $ProcessCheck = [Microsoft.ConfigurationManagement.ApplicationManagement.ProcessInformation]::new()
        $ProcessInfo = [Microsoft.ConfigurationManagement.ApplicationManagement.ProcessDisplayName]::new()

        # Fill up Parameters
        Write-Verbose "Fill the SDK-Objects"
        $ProcessCheck.Name = $Executable
        $ProcessInfo.DisplayName = $ExeInfo
        $ProcessInfo.Language = 'en-us' #

        # Create later Object
        Write-Verbose "Create Final Object for the later ApplicationManagement-Put"
        $ProcessCheck.DisplayInfo.Add($ProcessInfo)

        # Get the Application-Object
        Write-Verbose "Get Application-Information $($ApplicationName)"
        $App = Get-CMApplication -Name $ApplicationName

        # Convert to Application-SDK-Object
        Write-Verbose "Create App-SDK-Object"
        $AppInfo = ConvertTo-CMApplication -InputObject $App
        # Make the Change/Addition to the Object

        Write-Verbose "Get DeploymentType-Count - used by FOR-Call"
        [Int]$i = 0
        $DTCount = $AppInfo.DeploymentTypes.Count

        Write-Verbose "Add new Process List in $($DTCount) DeploymentType(s)"
        For ($i; $i -le ($DTCount -1); $i++)
        {
            $AppInfo.DeploymentTypes[$i].Installer.InstallProcessDetection.ProcessList.Add($ProcessCheck)
        }
        
        Write-Verbose "Application-SDK-Object prepared/set - Apply the Change"
        $objApp = ConvertFrom-CMApplication -InputObject $AppInfo
        $objApp.Put()
        Return "Success"
    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
        Return "Failure"
    }
}

Set-CMApplicationInstallBehavior -ApplicationName CMPivot -Clear -Verbose