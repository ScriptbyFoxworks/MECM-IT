<#
.Synopsis
   Enable-DistributionPointMCC
.DESCRIPTION
   This Function will activate the DOINC-Installation and set the corresponding Flag-Settings.
.EXAMPLE
   Enable-DistributionPointMCC -DPNameFQDN 'DP02.FOXWORKS.INTERNAL' -CacheSize 33 -RetainCache 0 -Verbose
.REQUIREMENTS
   PowerShell: 5.1.17763.1007
   ConfigMgrCmdLetModule: 5.2002.1083.2000
   ConfigMgr-Console must be installed
   ConfigMgr-Drive must be loaded
#>
Function Enable-DistributionPointMCC
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [String]$DPNameFQDN,
    [Parameter(Mandatory=$true)]
    [Int]$CacheSize,
    [Parameter(Mandatory=$true)]
    [ValidateSet(0,1)]
    [Int]$RetainCache
)

    Try
    {
        Write-Verbose "Connect to CMConnectionManager - prepare SiteControlFile-Change"
        $ConfigMgrCon = Get-CMConnectionManager
        #$ConfigMgrCon.RefreshScf($SiteCode)
        # Get a session handle for the site control file so we can update it
        $scf = Invoke-CMWmiMethod -ClassName SMS_SiteControlFile -MethodName GetSessionHandle
 
        # Refresh the WMI copy of the site control file to ensure we have the latest copy
        $refresh = Invoke-CMWmiMethod -ClassName SMS_SiteControlFile -MethodName RefreshSCF -Parameter @{'SiteCode'=$ConfigMgrCon.NamedValueDictionary.ConnectedSiteCode}
        
        Write-Verbose "Build ConfigMgr-SearchObject for SMS Distribution Point: $($DPNameFQDN)"
        $Search = [Microsoft.ConfigurationManagement.PowerShell.Provider.SmsProviderSearch]::new()
        $Search.Add('Rolename','SMS Distribution Point')
        $Search.Add('NetworkOSPath',"\\$($DPNameFQDN)")
        $SearchResult = Invoke-CMWmiQuery -ClassName SMS_SCI_SysResUse -Search $Search

        If ($SearchResult.Count -eq 1)
        {
            Write-Verbose "Save Embedded Properties to Varialbe - used later to change an apply new Objects"
            $EmbeddedObj = $SearchResult.EmbeddedProperties

            Write-Verbose "Enum each Property - use a Switch-Statement to set things specific"
            
            Foreach ($PropObj in $SearchResult.Props)
            {
                Switch ($PropObj.PropertyName)
                {
                    "Flags" {
                                    Write-Verbose "Modify EmbeddedObject $($PropObj.PropertyName)"
                                    $EmbeddedObj.Flags.Value = 4                        
                                   }
                    "LocalDriveDOINC" {
                                        Write-Verbose "Modify EmbeddedObject $($PropObj.PropertyName)"
                                        $EmbeddedObj.LocalDriveDOINC.Value1 = 'Automatic'
                                      }
                    "DiskSpaceDOINC" {
                                        Write-Verbose "Modify EmbeddedObject $($PropObj.PropertyName)"
                                        $EmbeddedObj.DiskSpaceDOINC.Value = $CacheSize
                                        $EmbeddedObj.DiskSpaceDOINC.Value1 = 'GB'
                                     }
                    "RetainDOINCCache" {
                                        Write-Verbose "Modify EmbeddedObject $($PropObj.PropertyName)"
                                        $EmbeddedObj.RetainDOINCCache.Value = $RetainCache
                                       }
                    "AgreeDOINCLicense" {
                                            Write-Verbose "Modify EmbeddedObject $($PropObj.PropertyName)"
                                            $EmbeddedObj.AgreeDOINCLicense.Value = 1
                                        }
                }
            }
            
            Write-Verbose "Apply the new EmbeddedObjects"
            $SearchResult.EmbeddedProperties = $EmbeddedObj
            $SearchResult.Put()

            Write-Verbose "Commit SiteContorlFile-Change"            
            $commit = Invoke-CMWmiMethod -ClassName SMS_SiteControlFile -MethodName CommitSCF -Parameter @{'SiteCode'=$ConfigMgrCon.NamedValueDictionary.ConnectedSiteCode}
            
            Write-Verbose "Release Site ControlFile"
            $release = Invoke-CMWmiMethod -ClassName SMS_SiteControlFile -MethodName ReleaseSessionHandle -Parameter @{'SessionHandle'=$($scf.SessionHandle)}  

            Return "Success"
        }
    }
    Catch
    {
        Write-Error "Exception Type: $($_.Exception.GetType().FullName)"
        Write-Error "Exception Message: $($_.Exception.Message)"
        Write-Error "Exception Stack: $($_.ScriptStackTrace)"
        Return "Failure"
    }
}


Enable-DistributionPointMCC -DPNameFQDN 'DP02.FOXWORKS.INTERNAL' -CacheSize 33 -RetainCache 0 -Verbose