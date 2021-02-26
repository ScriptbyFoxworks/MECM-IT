<#
.Synopsis
   Set-FileACLPerm
.DESCRIPTION
   This Function is using the system.security.accesscontrol.filesecurity Object to Set or Reapply NTFS-Permission to a File. The FilePath will
   be validated in the Paramblock. The UserObjectname-Parameter musst be in the Format DOMAIN\USERNAME or BuiltIn NT AUTHORITY\SYSTEM
.EXAMPLE
   Set-FileACLPerm -FilePath "C:\Temp\FOXWORKS\FileToChangePerm.txt" -UserObjectName 'FOXWORKS\Heidi' -ACLType Allow -ACLPerm Modify -Verbose
.Requirements
   Elevated Permissions
#>
Function Set-FileACLPerm
{
[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    [String]$FilePath,
    [Parameter(Mandatory=$true,
     HelpMessage="Please provide an Account in the Format DOMAIN\USERNAME or BuiltIn NT AUTHORITY\SYSTEM")]
    [String]$UserObjectName,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Allow", "Deny")]
    [String]$ACLType,
    [Parameter(Mandatory=$true)]
    [ValidateSet("FullControl", "Modify", "Read")]
    [String]$ACLPerm
)
    Begin
    {
        Write-Verbose "Get-File Object $($FilePath)"
        $objFile = Get-Item -Path $FilePath

        Write-Verbose "Prepare System.Security.AccessControl.FileSecurity Object and fill it with the Parameters"
        $objFileSec = [system.security.accesscontrol.filesecurity]::new()
        $objFileSecType = [System.Security.AccessControl.AccessControlType]::$($ACLType)
        $objFileSecPerm = [System.Security.AccessControl.FileSystemRights]::$($ACLPerm)
        $objFileSecRule = [System.Security.AccessControl.FileSystemAccessRule]::new($UserObjectName,$objFileSecPerm,$objFileSecType)
    }
    Process
    {
        Write-Verbose "Process FileObject Add-ACL-Rule and Set the ACL-Perm"
        $objFileSec.AddAccessRule($objFileSecRule)
        $objFile.SetAccessControl($objFileSec)
    }
    End
    {
        Write-Verbose "Process File-ACL successfully - return it"
        Return "Success"
    }
}

Set-FileACLPerm -FilePath "C:\Temp\FOXWORKS\FileToChangePerm.txt" -UserObjectName 'FOXWORKS\Heidi' -ACLType Allow -ACLPerm Modify -Verbose
