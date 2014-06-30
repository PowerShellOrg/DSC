function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VMHost
	)

    if((Get-WindowsFeature -Name Hyper-V).installed){
        $Ensure = $true  # if true
    }
    else {
        $Ensure = $false  # if false
    }

    if ($ensure -eq $true) {
        # Check if Hyper-V module is present for Hyper-V cmdlets
        $poshHv = [system.boolean]((Get-Module -ListAvailable -Name Hyper-V))
        $vmHostObj = Get-VMHost $VmHost #-ErrorAction SilentlyContinue
    }

	$returnValue = @{
		VMHost = [System.String]$vmHostObj.ComputerName
		Ensure = [System.String]$Ensure
		VirtualDiskPath = [System.String]$vmHostObj.VirtualHardDiskPath
		VirtualMachinePath = [System.String]$vmHostObj.VirtualMachinePath
		VirtualMachineMigration = [System.String]$vmHostObj.VirtualMachineMigrationEnabled
		EnhancedSessionMode = [System.String]$vmHostObj.EnableEnhancedSessionMode
		HyperVPowerShell = [System.Boolean]$poshHv
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VMHost,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String]
		$VirtualDiskPath,

		[System.String]
		$VirtualMachinePath,

		[ValidateSet("True","False","","0","1")]
		[System.String]
		$VirtualMachineMigration = 2,

		[ValidateSet("True","False","","0","1")]
		[System.String]
		$EnhancedSessionMode = 2
	)

    if($Ensure -eq 'Present') {

        Write-Verbose -Message "Checking if Hyper-V is enabled ..."
        if ((Get-WindowsFeature -Name Hyper-V).installed){
            Write-Verbose -Message "The Hyper-V Role is present."
        }
        else{
            Write-Verbose -Message "Installing the Hyper-V Role ..."
            Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature
            $global:DSCMachineStatus = 1
        }

        Write-Verbose -Message "Checking if Hyper-V PowerShell modules are installed ..."
        if ((Get-WindowsFeature -Name Hyper-V-PowerShell).installed){
            Write-Verbose "The Hyper-V PowerShell module is present."
        }
        else {
            Write-Verbose -Message "Installing the Hyper-V PowerSehll module ..."
            Install-WindowsFeature -Name Hyper-V-PowerShell -IncludeAllSubFeature
        }

        
        # Do not continue processing if reboot is pending.
        if (!$global:DSCMachineStatus -eq 1) {

            $vmHostObj = Get-VMHost $VMHost -ErrorAction SilentlyContinue

            if ($VirtualDiskPath) {
                Write-Verbose -Message "Checking if $VirtualDiskPath matches the current configuration ..."
                if ($vmHostObj.VirtualHardDiskPath -eq $VirtualDiskPath){
                    Write-Verbose -Message "$VirtualDiskPath is correctly set as the default virtual disk path"
                }
                else {

                    Write-Verbose -Message "Desired virtual disk path $VirtualDiskPath does not match current path of $vmHostObj.VirtualHardDiskPath"

                    Write-Verbose -Message "Validating the path $VirtualDiskPath ..."
                    if (!(Test-Path -Path $VirtualDiskPath)) {
                        Write-Verbose -Message "The path does not already exist.  Building the path ..."

                        Write-Verbose -Message "Validating the drive letter ..."
                        try {
                        
                            if (Get-Partition -DriveLetter $VirtualDiskPath[0] -ErrorAction SilentlyContinue){

                                Write-Verbose -Message "Drive letter $VirtualDiskPath[0] is valid, creating folder ..."
                                New-Item -Path $VirtualDiskPath -ItemType Directory
                            }
                        } 
                        catch [System.Management.Automation.ActionPreferenceStopException] {
                            Throw "Drive letter $VirtualDiskPath[0] does not exist on this system. Configuration cannot be applied ..."
                        }
                    
                    }

                    if ((Test-Path -Path $VirtualDiskPath)) {
                        Set-VMHost -VirtualHardDiskPath $VirtualDiskPath
                        Write-Verbose -Message "Default virtual disk path $vmHostObj.VirtualHardDiskPath matches desired $VirtualDiskPath"
                    }
                    else{
                        Throw "The path is not valid to store virtual disks."
                    }
                }
            }


            if ($VirtualMachinePath) {
            
                Write-Verbose -Message "Checking if $VirtualMachinePath matches the current configuration ..."
            
                if ($vmHostObj.VirtualMachinePath -eq $VirtualMachinePath){
                    Write-Verbose -Message "$VirtualMachinePath is correctly set as the default virtual machine path"
                }
                else {
                
                    Write-Verbose -Message "Desired virtual disk path $VirtualMachinePath does not match current path of $vmHostObj.VirtualMachinePath"

                    Write-Verbose -Message "Validating machine configuration path $VirtualMachinePath ..."
                    if (!(Test-Path -Path $VirtualMachinePath)) {
                    
                        Write-Verbose -Message "Validating drive letter $VirtualMachinePath ..."
                        try {
                            if (Get-Partition -DriveLetter $VirtualMachinePath[0] -ErrorAction SilentlyContinue){
                                Write-Verbose -Message "Drive letter $VirtualMachinePath[0] is valid, creating folder ..."
                                New-Item -Path $VirtualMachinePath -ItemType Directory
                            }
                        } 
                        catch [System.Management.Automation.ActionPreferenceStopException] {
                            Throw "Drive letter $VirtualMachinePath[0] does not exist on this system.  Configuration cannot be applied ..."
                        }
                    
                    }

                    if ((Test-Path -Path $VirtualMachinePath)) {                                
                        Set-VMHost -VirtualMachinePath $VirtualMachinePath
                        Write-Verbose -Message "Default virtual disk path $vmHostObj.VirtualMachinePath matches desired $VirtualDiskPath"
                    }
                    else{
                        Throw "The path is not valid to store virtual machine configurations"
                    }
                }
            }

            if ($VirtualMachineMigration -eq $true) {
                Write-Verbose -Message "Checking if virtual machine migration is set to True ..."
                if ($vmHostObj.VirtualMachineMigrationEnabled -eq $true){
                    Write-Verbose -Message "Virtual machine migration is correctly set to $VirtualMachineMigration"
                }
                else {
                    Write-Verbose -Message "Enabling virtual machine migration for any network ..."
                    Set-VMHost -UseAnyNetworkForMigration $true
                    Enable-VMMigration
                }
            }
            elseif ($VirtualMachineMigration -eq $false) {
                if ($vmHostObj.VirtualMachineMigrationEnabled -eq $false){
                    Write-Verbose -Message "Virtual machine migration is correctly set to $VirtualMachineMigration"
                }
                else {
                    Write-Verbose -Message "Disabling virtual machine migration ..."
                    Disable-VMMigration
                }
            }

            if ($EnhancedSessionMode -eq $true) {
                Write-Verbose -Message "Checking if virtual machine migration is set to True ..."
                if ($vmHostObj.EnableEnhancedSessionMode -eq $true){
                    Write-Verbose -Message "Enhanced session mode is correctly set to $EnhancedSessionMode"
                }
                else {
                    Write-Verbose -Message "Enabling enhanced session mode ..."
                    Set-VMHost -EnableEnhancedSessionMode $true
                }
            }
            elseif ($EnhancedSessionMode -eq $false) {
                if ($vmHostObj.EnableEnhancedSessionMode -eq $false){
                    Write-Verbose -Message "Enhanced session mode is correctly set to $EnhancedSessionMode"
                }
                else {
                    Write-Verbose -Message "Disabling enhanced session mode ..."
                    Set-VMHost -EnableEnhancedSessionMode $false
                }
            }
        }
    }
    else {  # Hyper-V is set to absent
    
        Write-Verbose -Message "Checking if Hyper-V is enabled ..."
        
        if ((Get-WindowsFeature -Name Hyper-V).installed){
            
            Write-Verbose -Message "Checking if this is Hyper-V Server ..."

            If ((Get-WindowsEdition -Online).Edition -ne 'ServerHyperCore') {
                Write-Verbose -Message "Removing the Hyper-V Role ..."
                Uninstall-WindowsFeature -Name Hyper-V -IncludeManagementTools
                $global:DSCMachineStatus = 1
            }
            else {
                Write-Verbose -Message "Hyper-V cannot be removed from the Hyper-V Server Edition"
            }
        }
        else{
            Write-Verbose -Message "Hyper-V Role is not installed ..."
        }
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$VMHost,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure,

		[System.String]
		$VirtualDiskPath,

		[System.String]
		$VirtualMachinePath,

		[ValidateSet("True","False","","0","1")]
		[System.String]
		$VirtualMachineMigration = 2,

		[ValidateSet("True","False","","0","1")]
		[System.String]
		$EnhancedSessionMode = 2
	)

    if($Ensure -eq 'Present') {

        Write-Verbose -Message "Checking if Hyper-V is enabled ..."
        if ((Get-WindowsFeature -Name Hyper-V).installed){
            Write-Verbose -Message "The Hyper-V Role is present."
            Write-Verbose -Message "Checking if Hyper-V PowerShell modules are installed ..."
            if ((Get-WindowsFeature -Name Hyper-V-PowerShell).installed){
                Write-Verbose "The Hyper-V PowerShell module is present."
            }
            else {
                Write-Verbose -Message "The Hyper-V PowerShell module is missing. Hyper-V is not properly installed."
                Return $false
            }
        }
        else{
            Write-Verbose -Message "The Hyper-V Role is not installed"
            Return $false
        }

        $vmHostObj = Get-VMHost $VMHost -ErrorAction SilentlyContinue

        if ($VirtualDiskPath) {
            Write-Verbose -Message "Checking if $VirtualDiskPath matches the configuration ..."
            if ($vmHostObj.VirtualHardDiskPath -eq $VirtualDiskPath){
                Write-Verbose -Message "$VirtualDiskPath is correctly set as the default virtual disk path"
                Return $true
            }
            else {
                Write-Verbose -Message "$VirtualDiskPath does not match the current setting of $vmHostObj.VirtualHardDiskPath."
                Return $false
            }
        }


        if ($VirtualMachinePath) {
            Write-Verbose -Message "Checking if $VirtualMachinePath matches the configuration ..."
            if ($vmHostObj.VirtualMachinePath -eq $VirtualMachinePath){
                Write-Verbose -Message "$VirtualMachinePath is correctly set as the default virtual machine path"
                Return $true
            }
            else {
                Write-Verbose -Message "$VirtualMachinePath is not set as the default virtual machine path"
                Return $false
            }
        }

        if ($VirtualMachineMigration -eq $true) {
            Write-Verbose -Message "Checking if virtual machine migration is set to True ..."
            if ($vmHostObj.VirtualMachineMigrationEnabled -eq $true){
                Write-Verbose -Message "Virtual machine migration is correctly set to $VirtualMachineMigration"
                Return $true
            }
            else {
                Write-Verbose -Message "Virtual machine migration is not set to $VirtualMachineMigration"
                Return $false
            }
        }
        elseif ($VirtualMachineMigration -eq $false) {
            if ($vmHostObj.VirtualMachineMigrationEnabled -eq $false){
                Write-Verbose -Message "Virtual machine migration is correctly set to $VirtualMachineMigration"
                Return $true
            }
            else {
                Write-Verbose -Message "Virtual machine migration is not set to $VirtualMachineMigration"
                Return $false
            }
        }

        if ($EnhancedSessionMode -eq $true) {
            Write-Verbose -Message "Checking if virtual machine migration is set to True ..."
            if ($vmHostObj.EnableEnhancedSessionMode -eq $true){
                Write-Verbose -Message "Enhanced session mode is correctly set to $EnhancedSessionMode"
                Return $true
            }
            else {
                Write-Verbose -Message "Enhanced session mode is not set to $EnhancedSessionMode"
                Return $false
            }
        }
        elseif ($EnhancedSessionMode -eq $false) {
            if ($vmHostObj.EnableEnhancedSessionMode -eq $false){
                Write-Verbose -Message "Enhanced session mode is correctly set to $EnhancedSessionMode"
                Return $true
            }
            else {
                Write-Verbose -Message "Enhanced session mode is not set to $EnhancedSessionMode"
                Return $false
            }
        }
    }
    else { # Ensure is set to Absent

        Write-Verbose -Message "Checking if Hyper-V is not enabled ..."
        if ((Get-WindowsFeature -Name Hyper-V)){
            Write-Verbose -Message "The Hyper-V Role is present."
            Return $false
        }
        else{
            Write-Verbose -Message "The Hyper-V Role is not installed"
            Return $true
        }
    }
}

Export-ModuleMember -Function *-TargetResource



