<#
.Synopsis
   Get-CollectionMemberships
.DESCRIPTION
   This Function will grab the Collection-Memberships of a CMDevice. The Result is stored in a HashTable and will be returned in a GridView.
.EXAMPLE
   Get-Collectionmemberships -SiteCode 'FOX' -SiteServer 'CM01.FOXWORKS.INTERNAL' -Hostname 'WS01' -Verbose
#>
Function Get-CollectionMemberships
{
[CmdLetBinding()]
Param
(
[Parameter(Mandatory=$True)]
[String]$Hostname,
[Parameter(Mandatory=$True)] 
[String]$SiteCode,
[Parameter(Mandatory=$True)]
[String]$SiteServer
)

Write-Verbose "Hostname: $($Hostname)"
Write-Verbose "SiteCode: $($SiteCode)"
Write-Verbose "SiteServer: $($SiteServer)"

Try
{
    $CMResource= gwmi -ComputerName $SiteServer -Namespace root\sms\site_$($SiteCode) -Query "Select ResourceID from SMS_R_System where Name = '$($Hostname)'"
    If ($CMResource -ne $null -or $CMResource.Count -ge 2)
    {
        Write-Verbose "Found the following ResourceID $($CMResource.ResourceId) for the Hostname $($Hostname)"
        Write-Verbose "Query Collections with a member of the ResourceID $($CMResource.ResourceID)"
        $ColMembers = gwmi -ComputerName $SiteServer -Namespace root\sms\site_$($SiteCode) -Query "select CollectionID from SMS_FullCollectionMembership where ResourceID = '$($CMResource.ResourceID)'" 
    }
    Else
    {
        Write-Verbose "Unable to Process Request - the Item is not found or duplicated Entries"
    }
}
Catch
{
    Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)" 
    Write-Verbose "Exception Message: $($_.Exception.Message)"
    Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
}

$Memberships = New-Object System.Collections.ArrayList

    ForEach ($ColMember in $ColMembers)
    {
        Try
        {
            $ColQuery = gwmi -ComputerName $SiteServer -Namespace root\sms\site_$SiteCode -Query "Select Name from SMS_Collection where CollectionID = '$($ColMember.CollectionID)'" 
            Write-Verbose "Found Membership for Collection $($ColQuery.Name)"
            $QueryInfo = @{
                            CollectionID = $ColMember.CollectionID
                            CollectionName = $ColQuery.Name
                          }

                $OutPut =  New-Object PSObject -Property $QueryInfo
                [void]$Memberships.Add($OutPut)
        }
        Catch
        {
            Write-Verbose "Exception Type: $($_.Exception.GetType().FullName)" 
            Write-Verbose "Exception Message: $($_.Exception.Message)"
            Write-Verbose "Exception Stack: $($_.ScriptStackTrace)"
        }
    }
Return $Memberships | Sort-Object CollectionID | Out-GridView -Title "Collection Memberships of the System $($Hostname)"
}

Get-Collectionmemberships -SiteCode 'FOX' -SiteServer 'CM01.FOXWORKS.INTERNAL' -Hostname 'WS01' -Verbose