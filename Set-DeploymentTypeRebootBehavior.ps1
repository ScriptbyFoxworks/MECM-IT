<#
.Synopsis
   Set-DeploymentTypeRebootBehavior
.DESCRIPTION
   This Function will change for one specific or all Deployments of an Application the PostInstallRebootBehavior
   To execute the Function the ConfigMgr-CmdLet-Binary must be loaded & PSDrive set already.
.EXAMPLE
   Set-DeploymentTypeRebootBehavior -ApplicatioName 'Notepad++' -Behavior NoAction -Verbose
.EXAMPLE
   Set-DeploymentTypeRebootBehavior -ApplicatioName 'CMTrace' -DeploymentTypeName 'CMTrace Install x86' -Behavior ProgramReboot -Verbose
.REMARKS
   Configuration Manager Cmdlet Libary must be loaded
   Powershell 5.1.17763.316
#>
Function Set-DeploymentTypeRebootBehavior
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [String]$ApplicatioName,
    [Parameter(Mandatory=$false)]
    [String]$DeploymentTypeName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("BasedOnExitCode","ForceLogOff","ForceReboot","NoAction","ProgramReboot")]
    [String]$Behavior
)

    Write-Verbose "Create TypeDefintion for RebootBehaviorType: $($Behavior)"
    $BehaviorType = [Microsoft.ConfigurationManagement.ApplicationManagement.PostExecutionBehavior]::$($Behavior)

    Write-Verbose "Get Application/DeploymentType Object"
    $AppObj = Get-CMApplication -ApplicationName $ApplicatioName -Fast -ErrorAction Stop
    
    $DTObjSDK = ConvertTo-CMApplication -InputObject $AppObj

    Write-Verbose "Start Looping through DeploymentTypes depending on Parameter"
    Try
    {
        If ($DTObjSDK -ne $null -and $DeploymentTypeName -eq '')
        {
            Write-Verbose "Get a Condition where SDKObj is not empty and no DT-Parameter set - modify all Deployment-Types"
            Write-Verbose "Get DeploymentType-Count - used by FOR-Call"
            [Int]$i = 0
            $DTCount = $AppObj.NumberOfDeploymentTypes

            Write-Verbose "Change RebootBehavior in $($DTCount) DeploymentType(s)"
            For ($i; $i -le ($DTCount -1); $i++)
            {
                Write-Verbose "Process against $($DTObjSDK.DeploymentTypes[$i].Title)"
                $DTObjSDK.DeploymentTypes[$i].Installer.PostInstallBehavior = $BehaviorType
            }
        }
        ElseIf ($DTObjSDK -ne $null -and $DeploymentTypeName.Length -ge 1)
        {
            Write-Verbose "Get a Condition where SDKObj is not empty and DT-Parameter $($DeploymentTypeName) has been specified"            
            Write-Verbose "Get DeploymentType-Count - used by FOR-Call"
            [Int]$i = 0
            $DTCount = $AppObj.NumberOfDeploymentTypes

            Write-Verbose "Change RebootBehavior DeploymentType: $($DeploymentTypeName) - Total DT's in Application: $($DTCount)"
            For ($i; $i -le ($DTCount -1); $i++)
            {
                If ($DTObjSDK.DeploymentTypes[$i].Title -eq $DeploymentTypeName)
                {
                    Write-Verbose "Found Match - Process against DeploymentTypeName: $($DTObjSDK.DeploymentTypes[$i].Title)"
                    $DTObjSDK.DeploymentTypes[$i].Installer.PostInstallBehavior = $BehaviorType
                }
            }
        }
    
        Write-Verbose "Apply DeploymentType-SDK-Object changes and set a Put on the Instance"
        $objApp = ConvertFrom-CMApplication -InputObject $DTObjSDK
        $objApp.Put()

        Return "Successfully applied changes"
    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
        Return "Error while applying changes"
    }
}

Set-DeploymentTypeRebootBehavior -ApplicatioName 'CMTrace' -Behavior NoAction -Verbose

