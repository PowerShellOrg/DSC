#####
# Unzip cSystemCenterManagement.zip to C:\Program Files\WindowsPowerShell\Modules folder on server you are running this script from
# Create Share called "DSC", if the share is on another virtual machine besides DC01, change FileShr parameter below.
# Create folder called DSCResources under share folder and copy cSystemCenterManagement.zip to it.
#
# PowerShell Desired State Configuration (DSC) Resources for System Center (Revisited)
# http://www.systemcentercentral.com/powershell-desired-state-configuration-dsc-resources-for-system-center-revisited/
#####

$FileShr = "\\DC01\DSC"

Configuration CopyDSCConfig 
{
    param (
        [Parameter(Mandatory)]
        [string]$FileShr
    )

    Node SCOM01
    {
        Archive cSysCtrZip {            Ensure = "Present"            Path = "$FileShr\DSCResources\cSystemCenterManagement.zip"            Destination = "$Env:ProgramFiles\WindowsPowerShell\Modules"            Force = $True        }
    }
}

CopyDSCConfig -FileShr $FileShr -OutputPath "$Env:Temp\CopyDSCConfig"Start-DscConfiguration -Path "$Env:Temp\CopyDSCConfig" -Wait -Force -Verbose -ErrorAction ContinueConfiguration SCOMDSCConfiguration 
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileShr
    )

    Import-DscResource -ModuleName cSystemCenterManagement

    Node SCOM01
    {
        SCOMImportMP AlertAttMP
        {
            Ensure = "Present"
            MPName = "Microsoft.SystemCenter.AlertAttachment"
            MPSourcePath = "\\DC01\DSC\mp\Microsoft.SystemCenter.AlertAttachment.mpb"                                        
        }

        Package InstallWinBaseMP
        {
            Ensure = "Present"
            Name = "System Center Management Pack-Windows Server Operating System"
            Path = "$FileShr\mp\System%20Center%20Management%20Pack-Windows%20Server%20Operating%20System.msi"
            ProductId = "DF6ADE8C-5C88-41BC-87FD-AE3BA00F24E9"
        }

        SCOMBulkMP ImportWinOSMp
        {
            Ensure = "Present"
            MPSourcePath = "C:\Program Files (x86)\System Center Management Packs\System Center Management Pack-Windows Server Operating System"
            DependsOn = "[Package]InstallWinBaseMp"
        }

    }
}

CopyDSCConfig -FileShr $FileShr -OutputPath "$Env:Temp\SCOMDSCConfiguration"Start-DscConfiguration -Path "$Env:Temp\SCOMDSCConfiguration" -Wait -Force -Verbose -ErrorAction Continue