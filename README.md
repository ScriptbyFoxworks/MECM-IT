# MECM-IT
Automation Scripts, Help-Functions for Microsoft Endpoint Configuration Manager

This Script is using the CM-Messaging-Dll to get the Content-Location-Records. The Output is a simple HashTable - containing the Name, ADSite, IPSubnet, DPType
We need two Parameters the PackageID and the StoredPkgVersion (SQL: Select Name, PkgID, StoredPkgVersion from DBO.SMSPackages)
Another possiblity is to use the Content_UniqueID SQL:(Select PkgID, Content_UniqueID, ContentVersion from CI_ContentPackages) for SuperPeers in case of Applications
