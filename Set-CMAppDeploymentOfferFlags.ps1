<#
.Synopsis
   Set-CMAppDeploymentOfferFlags
.DESCRIPTION
   This Function will set ApplicationDeployment OfferFlags based on the Switches 
   The Input must be the AssignmentUniqueID from SMS_DeploymentSummary WMI-Classes
   Only if the BIT-Comparision find a mismatch if the Input the Flag will be set. Already existing Flags will be not touched.
.EXAMPLE
   Set-CMAppDeploymentOfferFlags -AssignmentUniqueID $Deployment.AssignmentUniqueID -PreDeploy -EnableProcessTermination -AllowUsersToRepair -Verbose
.REMARKS
   Configuration Manager Cmdlet Libary must be loaded
#>
Function Set-CMAppDeploymentOfferFlags
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [String]$AssignmentUniqueID,
    [Switch]$PreDeploy,
    [Switch]$EnableProcessTermination,
    [Switch]$AllowUsersToRepair
)

    Begin
    {
        Write-Verbose "Create HashTable to Process OfferFlags"
        $OfferFlags = @{
                       'PREDEPLOY' = 1
                       'ENABLEPROCESSTERMINATION' = 4
                       'ALLOWUSERSTOREPAIRAPP' = 8
                       }
    }
    Process
    {
        Write-Verbose "AssignmentUniqueID: $($AssignmentUniqueID)"
        Try
        {
            Write-Verbose "Try to get ApplicationDeployment Instance with ID: $($AssignmentUniqueID)"
            $AppDeployment = Get-CMApplicationDeployment -DeploymentId $AssignmentUniqueID
            $OfferType = $AppDeployment.OfferFlags
        }
        Catch
        {
            Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
            Write-Error "Exception Message: $($_.Exception.Message)"
            Write-Error "Exception Stack: $($_.ScriptStackTrace)"
        }

        [Int]$FlagToSet = 0
        Switch($PreDeploy)
        {
            'True' {Write-Verbose "PreDeploy-Switch will be processed"
                       If (($OfferType -band $OfferFlags.PREDEPLOY) -eq 0)
                       {
                            Write-Verbose "Bit-Comparision done - need to set this Flag: $($OfferFlags.PREDEPLOY)"
                            $FlagToSet += $OfferFlags.PREDEPLOY
                       }
                   }
        }

        Switch($EnableProcessTermination)
        {
            'True' {Write-Verbose "EnableProcessTermination-Switch will be processed"
                       If (($OfferType -band $OfferFlags.ENABLEPROCESSTERMINATION) -eq 0)
                       {
                            Write-Verbose "Bit-Comparision done - need to set this Flag: $($OfferFlags.ENABLEPROCESSTERMINATION)"
                            $FlagToSet += $OfferFlags.ENABLEPROCESSTERMINATION
                       }            
                   }
        }

        Switch($AllowUsersToRepair)
        {
            'True' {Write-Verbose "AllowUsersToRepairApp-Switch will be processed"
                       If (($OfferType -band $OfferFlags.ALLOWUSERSTOREPAIRAPP) -eq 0)
                       {
                            Write-Verbose "Bit-Comparision done - need to set this Flag: $($OfferFlags.ALLOWUSERSTOREPAIRAPP)"
                            $FlagToSet += $OfferFlags.ALLOWUSERSTOREPAIRAPP
                       }            

                   }
        }

        Write-Verbose "Do a simple SUM of the Flags"
        [Int]$NewFlag = $OfferType + $FlagToSet
        Write-Verbose "Original-OfferType: $($OfferType)"
        Write-Verbose "OfferFlagsToSet: $($FlagToSet)"
        Write-Verbose "NewFlagToSet: $($NewFlag)"

    }
    End
    {
        If ($OfferType -ne $NewFlag)
            {
            Try
            {
                Write-Verbose "Grab Application-Deployment Instance modify OfferFlags and execute Put-Method"
                $AppDeployment.OfferFlags = $NewFlag
                $AppDeployment.Put()

                Return "Success"
            }
            Catch
            {
                Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
                Write-Error "Exception Message: $($_.Exception.Message)"
                Write-Error "Exception Stack: $($_.ScriptStackTrace)"
            }
        }
        Else
        {
            Return "The specified Flags are already set - Verify your Input"
        }
    }
}

$AppDeployment = Get-CMApplicationDeployment -DeploymentId '{1BE46AA9-F396-4FD5-8325-331B29382454}'
$AppDeployment.AssignmentUniqueID | Set-CMAppDeploymentOfferFlags -PreDeploy -EnableProcessTermination -AllowUsersToRepair -Verbose
