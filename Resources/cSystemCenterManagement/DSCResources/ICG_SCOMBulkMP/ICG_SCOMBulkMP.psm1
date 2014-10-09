#######################################################################
# ICG_SCOMBulkMP DSC Resource
# DSC Resource to bulk import management packs into SCOM 2012
# 201401129 - Joe Thompson, Infront Consulting Group
#######################################################################

function Get-TargetResource
{
    [OutputType([hashtable])]
	param
    (
       	[ValidateSet("Present", "Absent")]
       	[String] $Ensure = "Present",
       	[parameter(Mandatory)]
    	[string] $MPSourcePath
    )

	$OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"

	If (!($OMReg))
   	{
       	Throw "Operations Manager PowerShell module not detected!"
   	}

   	$OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
	If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }

    $mpfiles = (Get-Item -Path "$MPSourcePath\*" -Include *.mp*).Name 

    If ($mpfiles)
    {
        $mpcnt = $mpfiles.Count 

        $InstallList = @()
        $InstalledMPs = Get-SCOMManagementPack |%{$_}|%{$_.name}
        foreach ($ManagementPack in $mpfiles)
        {
            $mpname = [System.IO.Path]::GetFileNameWithoutExtension($ManagementPack)
            If ($InstalledMPs -notcontains $mpname)
            {
                Write-Verbose -Message "$ManagementPack is missing."
                $InstallList += $ManagementPack
            }
            Else
            {
                Write-Verbose -Message "$ManagementPack is already installed!"
            }
        }

        $Instcnt = $InstallList.Count

        If ($Instcnt -gt 0)
        {
            Write-Verbose -Message "All Management Packs are not installed!"
            $returnValue = @{
                Ensure = "Absent"
                MPSourcePath = $MPSourcePath
            }
        }
        else
        {
            Write-Verbose -Message "All Management Packs are installed!"
            $returnValue = @{
                Ensure = "Present"
                MPSourcePath = $MPSourcePath
            }

        }
    }
    Else
    {
        Throw "Can't find source management pack files for comparison."
    }

    $returnValue;
}

function Set-TargetResource
{    
	param
    (
       	[ValidateSet("Present", "Absent")]
       	[System.String] $Ensure = "Present",
       	[parameter(Mandatory)]
		[string] $MPSourcePath
   	)

   	# Make sure we can get to OperationsManager PS Module
    
	$OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"

	If (!($OMReg))
   	{
       	Throw "Operations Manager PowerShell module not detected!"
   	}

    $OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
    If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }

    $mpfiles = (Get-Item -Path "$MPSourcePath\*" -Include *.mp*).Name 

    If ($mpfiles)
    {
        $mpcnt = $mpfiles.Count 

        $InstallList = @()
        $InstalledMPs = Get-SCOMManagementPack |%{$_}|%{$_.name}
        foreach ($ManagementPack in $mpfiles)
        {
            $mpname = [System.IO.Path]::GetFileNameWithoutExtension($ManagementPack)
            If ($InstalledMPs -notcontains $mpname)
            {
                Write-Verbose -Message "Adding $ManagementPack to import queue..."
                $InstallList += $ManagementPack
            }
            Else
            {
                Write-Verbose -Message "$ManagementPack is already installed!"
            }
        }

        $Instcnt = $InstallList.Count

        If ($Ensure -eq "Present")
        {
            If ($Instcnt -gt 0)
            {
                Write-Verbose -Message "Importing management packs from source folder $MPSourcePath"
                Set-Location $MPSourcePath
                Import-SCOMManagementPack -Fullname $InstallList -ErrorAction Continue
            }
        }
        Else
        {
            If ($Instcnt -gt 0)
            {
                $InstallList | Remove-SCOMManagementPack 

            }
        }
    }
    Else
    {
        Throw "Can't find source management pack files for comparison."
    }
}

function Test-TargetResource
{
    [OutputType([bool])]
   	param
   	(
       	[ValidateSet("Present", "Absent")]
       	[String] $Ensure = "Present",
       	[parameter(Mandatory)]
		[string] $MPSourcePath
   	)

    $returnValue = $True

    $OMReg = Get-ItemProperty "HKLM:\Software\Microsoft\System Center Operations Manager\12\Setup\Powershell\V2"

	If (!($OMReg))
	{
		Throw "Operations Manager role does not exist"
	}

    $OMPSModule = $OMReg.InstallDirectory + "OperationsManager"
    If (!(Get-Module OperationsManager)) { Import-Module $OMPSModule }
    
    $mpfiles = (Get-Item -Path "$MPSourcePath\*" -Include *.mp*).Name 

    If ($mpfiles)
    {
        $mpcnt = $mpfiles.Count 

        $InstallList = @()
        $InstalledMPs = Get-SCOMManagementPack |%{$_}|%{$_.name}
        foreach ($ManagementPack in $mpfiles)
        {
            $mpname = [System.IO.Path]::GetFileNameWithoutExtension($ManagementPack)
            If ($InstalledMPs -notcontains $mpname)
            {
                Write-Verbose -Message "$ManagementPack is missing."
                $InstallList += $ManagementPack
            }
            Else
            {
                Write-Verbose -Message "$ManagementPack is already installed!"
            }
        }

        $Instcnt = $InstallList.Count

        If ($Ensure -eq "Present")
        {
            If ($Instcnt -gt 0)
            {
                $returnValue = $False
            }
        }
        Else
        {
            If ($Instcnt -gt 0)
            {
                $returnValue = $False 

            }
        }
    }
    Else
    {
        Throw "Can't find source management pack files for comparison."
    }

    $returnValue;	
}


