<#
.Synopsis
   Start-CMSoftwareupdates
.DESCRIPTION
   This Function will trigger the ClientSDK to install Updates (including FeatureUpdates) which are assigned/deployed to this System. Can be used with RunScript-Feature 
.EXAMPLE
   Start-CMSoftwareUpdates -Verbose 
.REMARKS
   Evaluated-Permssions necessary
#>
Function Start-CMSoftwareUpdates
{
[CmdLetBinding()]
Param()

    Try
    {
        Write-Verbose "Try to access CCM_SoftwareUpdate."
        $objSoftwareUpdates = ([WMIClass]'root\ccm\clientsdk:CCM_SoftwareUpdate')
        Write-Verbose "Grab Instances of the Software Updates."
        $UpdateInstances = $objSoftwareUpdates.GetInstances()
        Write-Verbose "Total Count of Updates: $($UpdateInstances.Count)"

        If ($UpdateInstances.Count -ge 1)
        {
            Write-Verbose "Found at least one Update to process."
            $objUpdateManager = ([WMIClass]'root\ccm\clientsdk:CCM_SoftwareUpdatesManager')
            Write-Verbose "Invoke InstallUpdates Method"
            $UpdateAction = $objUpdateManager.InstallUpdates($UpdateInstances)

            Switch ($UpdateAction.ReturnValue)
            {
                0 {
                    Write-Verbose "Invoke SoftwareUpdate-Method Return Code: $($UpdateAction.ReturnValue)"
                    Return "Success"
                  }
                Default 
                  {
                    Write-Verbose "Invoke SoftwareUpdate-Method Return Code: $($UpdateAction.ReturnValue)"
                    Return "Failure - Unknown Exit Code"
                  }
            }
        }
    }
    Catch
    {
        Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Verbose "Exception Message: $($_.Exception.Message)"
        Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
        Return "Failure"
    }
}

Start-CMSoftwareUpdates -Verbose 
