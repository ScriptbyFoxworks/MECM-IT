<#
.Synopsis
   Get-CMAppDeploymentOfferFlags
.DESCRIPTION
   This Function will get Application Deployment OfferFlags  
   The Input must be the OfferFlags from SMS_DeploymentSummary WMI-Classes
   BIT-Comparision is used to gather this Information - The Information is retuned as Array
.EXAMPLE
   Get-CMAppDeploymentOfferFlags -FlagValue 40 -Verbose
   $AppDeployment = Get-CMApplicationDeployment -DeploymentId '{1BE46AA9-F396-4FD5-8325-331B29382454}'
   $AppDeployment.OfferFlags | Get-CMAppOfferFlags -Verbose
.REMARKS
    This Function allows INT-Values from a Pipe
#>
Function Get-CMAppDeploymentOfferFlags
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$True)]
    [ValidateNotNullOrEmpty()]
    [Int]$OfferFlags
)

    Begin
    {
        Write-Verbose "Prepare FlagOffer-HashTable"
        $OfferFlagsTable = @{
                           'PREDEPLOY' = 1
                           'ONDEMAND' = 2
                           'ENABLEPROCESSTERMINATION' = 4
                           'ALLOWUSERSTOREPAIRAPP' = 8
                           'RELATIVESCHEDULE' = 16
                           'HIGHIMPACTDEPLOYMENT' = 32 
                           }
        
        Write-Verbose "Results based on HashTable-Keys: $($OfferFlagsTable.Keys)"
    }
    Process
    {
        Write-Verbose "Create empty Output-Variable"
        $OutPut = @()

        Write-Verbose "Loop for each Key in HashTable"
        Foreach ($FlagType in $OfferFlagsTable.Keys)
        {
            Write-Verbose "Use Bit-Comparison-Operator to compare Flag: $($FlagType)"
            If (($OfferFlags -band $OfferFlagsTable.$FlagType) -ne 0)
            {
                Write-Verbose "Match Value found - add $($FlagType) to Output-Variable"
                $OutPut += $FlagType
            }
        }
    }
    End
    {
        Write-Verbose "Return the Result"
        Return $OutPut
    }
}

$AppDeployment = Get-CMApplicationDeployment -DeploymentId '{1BE46AA9-F396-4FD5-8325-331B29382454}'
$AppDeployment.OfferFlags | Get-CMAppDeploymentOfferFlags -Verbose

