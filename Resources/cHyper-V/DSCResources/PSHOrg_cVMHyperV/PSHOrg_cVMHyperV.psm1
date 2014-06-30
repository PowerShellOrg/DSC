function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [parameter(Mandatory = $true)]
        [String]$Name,

		[parameter(Mandatory = $true)]
		[String]$VhdPath
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    $vmobj = Get-VM -Name $Name -ErrorAction SilentlyContinue
    
    # Check if 1 or 0 VM with name = $name exist
    if($vmobj.count -gt 1)
    {
       Throw "More than one VM with the name $Name exist." 
    }
	 
	
	@{
		Name             = $Name
		VhdPath          = $vmObj.HardDrives[0].Path
		SwitchName       = $vmObj.NetworkAdapters[0].SwitchName
		State            = $vmobj.State
		Path             = $vmobj.Path
		Generation       = if($vmobj.Generation -eq 1){"Vhd"}else{"Vhdx"}
		StartupMemory    = $vmobj.MemoryStartup
		MinimumMemory    = $vmobj.MemoryMinimum
		MaximumMemory    = $vmobj.MemoryMaximum
		MACAddress       = $vmObj.NetWorkAdapters[0].MacAddress
		ProcessorCount   = $vmobj.ProcessorCount
		Ensure           = if($vmobj){"Present"}else{"Absent"}
		ID               = $vmobj.Id
		Status           = $vmobj.Status
		CPUUsage         = $vmobj.CPUUsage
		MemoryAssigned   = $vmobj.MemoryAssigned
		Uptime           = $vmobj.Uptime
		CreationTime     = $vmobj.CreationTime
		HasDynamicMemory = $vmobj.DynamicMemoryEnabled
		NetworkAdapters  = $vmobj.NetworkAdapters.IPAddresses
	}
}

function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
        # Name of the VM
        [parameter(Mandatory)]
        [String]$Name,
        
        # VHD associated with the VM
		[parameter(Mandatory)]
		[String]$VhdPath,
        
        # Virtual switch associated with the VM
		[String]$SwitchName,

        # State of the VM
		[ValidateSet("Running","Paused","Off")]
		[String]$State = "Off",

        # Folder where the VM data will be stored
		[String]$Path,

        # Associated Virtual disk format - Vhd or Vhdx
		[ValidateSet("Vhd","Vhdx")]
		[String]$Generation = "Vhd",

        # Startup RAM for the VM
		[ValidateRange(32MB,17342MB)]
        [UInt64]$StartupMemory,

        # Minimum RAM for the VM. This enables dynamic memory
		[ValidateRange(32MB,17342MB)]
        [UInt64]$MinimumMemory,

        # Maximum RAM for the VM. This enables dynamic memory
		[ValidateRange(32MB,1048576MB)]
        [UInt64]$MaximumMemory,

        # MAC address of the VM
		[String]$MACAddress,

        # Processor count for the VM
		[UInt32]$ProcessorCount,

        # Waits for VM to get valid IP address
		[Boolean]$WaitForIP,

        # If specified, shutdowns and restarts the VM as needed for property changes
		[Boolean]$RestartIfNeeded,

        # Should the VM be created or deleted
		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    Write-Verbose -Message "Checking if VM $Name exists ..."
    $vmObj = Get-VM -Name $Name -ErrorAction SilentlyContinue

    # VM already exists
    if($vmObj)
    {
        Write-Verbose -Message "VM $Name exists"

        # If VM shouldn't be there, stop it and remove it
        if($Ensure -eq "Absent")
        {
            Write-Verbose -Message "VM $Name should be $Ensure"
            Get-VM $Name | Stop-VM -Force -Passthru -WarningAction SilentlyContinue | Remove-VM -Force
            Write-Verbose -Message "VM $Name is $Ensure"
        }

        # If VM is present, check its state, startup memory, minimum memory, maximum memory,processor countand mac address
        # One cannot set the VM's vhdpath, path, generation and switchName after creation 
        else
        {
            # If the VM is not in right state, set it to right state
            if($vmObj.State -ne $State)
            {
                Write-Verbose -Message "VM $Name is not $State. Expected $State, actual $($vmObj.State)"
                SetVMState -Name $Name -State $State -WaitForIP $WaitForIP
                Write-Verbose -Message "VM $Name is now $State"
            }

            $changeProperty = @{}
            # If the VM does not have the right startup memory
            if($StartupMemory -and ($vmObj.MemoryStartup -ne $StartupMemory))
            {
                Write-Verbose -Message "VM $Name does not have correct startup memory. Expected $StartupMemory, actual $($vmObj.MemoryStartup)"
                $changeProperty["MemoryStartup"]=$StartupMemory
            }
            
            # If the VM does not have the right minimum or maximum memory, stop the VM, set the right memory, start the VM
            if($MinimumMemory -or $MaximumMemory)
            {
                $changeProperty["DynamicMemory"]=$true

                if($MinimumMemory -and ($vmObj.Memoryminimum -ne $MinimumMemory))
                {
                    Write-Verbose -Message "VM $Name does not have correct minimum memory. Expected $MinimumMemory, actual $($vmObj.MemoryMinimum)"
                    $changeProperty["MemoryMinimum"]=$MinimumMemory
                }
                if($MaximumMemory -and ($vmObj.Memorymaximum -ne $MaximumMemory))
                {
                    Write-Verbose -Message "VM $Name does not have correct maximum memory. Expected $MaximumMemory, actual $($vmObj.MemoryMaximum)"
                    $changeProperty["MemoryMaximum"]=$MaximumMemory
                }
            }

            # If the VM does not have the right processor count, stop the VM, set the right memory, start the VM
            if($ProcessorCount -and ($vmObj.ProcessorCount -ne $ProcessorCount))
            {
                Write-Verbose -Message "VM $Name does not have correct processor count. Expected $ProcessorCount, actual $($vmObj.ProcessorCount)"
                $changeProperty["ProcessorCount"]=$ProcessorCount
            }

            # Stop the VM, set the right properties, start the VM
            ChangeVMProperty -Name $Name -VMCommand "Set-VM" -ChangeProperty $changeProperty -WaitForIP $WaitForIP -RestartIfNeeded $RestartIfNeeded

            # If the VM does not have the right MACAddress, stop the VM, set the right MACAddress, start the VM
            if($MACAddress -and ($vmObj.NetWorkAdapters.MacAddress -notcontains $MACAddress))
            {
                Write-Verbose -Message "VM $Name does not have correct MACAddress. Expected $MACAddress, actual $($vmObj.NetWorkAdapters[0].MacAddress)"
                ChangeVMProperty -Name $Name -VMCommand "Set-VMNetworkAdapter" -ChangeProperty @{StaticMacAddress=$MACAddress} -WaitForIP $WaitForIP -RestartIfNeeded $RestartIfNeeded
                Write-Verbose -Message "VM $Name now has correct MACAddress."
            }
        }
    }

    # VM is not present, create one
    else
    {
        Write-Verbose -Message "VM $Name does not exists"
        if($Ensure -eq "Present")
        {
            Write-Verbose -Message "Creating VM $Name ..."
            
            $parameters = @{}
            $parameters["Name"] = $Name
            $parameters["VHDPath"] = $VhdPath

            # Optional parameters
            if($SwitchName){$parameters["SwitchName"]=$SwitchName}
            if($Path){$parameters["Path"]=$Path}
            if($Generation){$parameters["Generation"]=if($Generation -eq "Vhd"){1}else{2}}
            if($StartupMemory){$parameters["MemoryStartupBytes"]=$StartupMemory}
            $null = New-VM @parameters

            $parameters = @{}
            $parameters["Name"] = $Name
            if($MinimumMemory -or $MaximumMemory)
            {
                $parameters["DynamicMemory"]=$true
                if($MinimumMemory){$parameters["MemoryMinimumBytes"]=$MinimumMemory}
                if($MaximumMemory){$parameters["MemoryMaximumBytes"]=$MaximumMemory}
            }
            if($ProcessorCount){$parameters["ProcessorCount"]=$ProcessorCount}
            $null = Set-VM @parameters
                                    
            if($MACAddress)
            {
                Set-VMNetworkAdapter -VMName $Name -StaticMacAddress $MACAddress
            }
                
            SetVMState -Name $Name -State $State -WaitForIP $WaitForIP
            Write-Verbose -Message "VM $Name created and is $State"
        }
    }
}

function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		# Name of the VM
        [parameter(Mandatory)]
		[String]$Name,
        
        # VHD associated with the VM
		[parameter(Mandatory)]
		[String]$VhdPath,
        
        # Virtual switch associated with the VM
		[String]$SwitchName,

        # State of the VM
		[ValidateSet("Running","Paused","Off")]
		[String]$State = "Off",

        # Folder where the VM data will be stored
		[String]$Path,

        # Associated Virtual disk format - Vhd or Vhdx
		[ValidateSet("Vhd","Vhdx")]
		[String]$Generation = "Vhd",

        # Startup RAM for the VM
        [ValidateRange(32MB,17342MB)]
		[UInt64]$StartupMemory,

        # Minimum RAM for the VM. This enables dynamic memory
		[ValidateRange(32MB,17342MB)]
        [UInt64]$MinimumMemory,

        # Maximum RAM for the VM. This enables dynamic memory
		[ValidateRange(32MB,1048576MB)]
        [UInt64]$MaximumMemory,

        # MAC address of the VM
		[String]$MACAddress,

        # Processor count for the VM
		[UInt32]$ProcessorCount,

        # Waits for VM to get valid IP address
		[Boolean]$WaitForIP,

        # If specified, shutdowns and restarts the VM as needed for property changes
		[Boolean]$RestartIfNeeded,

        # Should the VM be created or deleted
		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    #region input validation
    
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    # Check if 1 or 0 VM with name = $name exist
    if((Get-VM -Name $Name -ErrorAction SilentlyContinue).count -gt 1)
    {
       Throw "More than one VM with the name $Name exist." 
    }
    
    # Check if $VhdPath exist
    if(!(Test-Path $VhdPath))
    {
        Throw "$VhdPath does not exists"
    }

    # Check if Minimum memory is less than StartUpmemory
    if($StartupMemory -and $MinimumMemory -and  ($MinimumMemory -gt $StartupMemory))
    {
        Throw "MinimumMemory($MinimumMemory) should not be greater than StartupMemory($StartupMemory)"
    }
    
    # Check if Minimum memory is greater than Maximummemory
    if($MaximumMemory -and $MinimumMemory -and ($MinimumMemory -gt $MaximumMemory))
    {
        Throw "MinimumMemory($MinimumMemory) should not be greater than MaximumMemory($MaximumMemory)"
    }
    
    # Check if Startup memory is greater than Maximummemory
    if($MaximumMemory -and $StartupMemory -and ($StartupMemory -gt $MaximumMemory))
    {
        Throw "StartupMemory($StartupMemory) should not be greater than MaximumMemory($MaximumMemory)"
    }        

    # Check if the generation matches the VhdPath extenstion
    if($Generation -and ($VhdPath.Split('.')[-1] -ne $Generation))
    {
        Throw "Generation $geneartion should match virtual disk extension $($VhdPath.Split('.')[-1])"
    }

    # Check if $Path exist
    if($Path -and !(Test-Path -Path $Path))
    {
        Throw "$Path does not exists"
    }

    #endregion

    $result = $false

    try
    {
        $vmObj = Get-VM -Name $Name -ErrorAction Stop

        if($Ensure -eq "Present")
        {
            if($vmObj.HardDrives.Path -notcontains $VhdPath){return $false}
            if($SwitchName -and ($vmObj.NetworkAdapters.SwitchName -notcontains $SwitchName)){return $false}
            if($state -and ($vmObj.State -ne $State)){return $false}
            if($StartupMemory -and ($vmObj.MemoryStartup -ne $StartupMemory)){return $false}
            if($MACAddress -and ($vmObj.NetWorkAdapters.MacAddress -notcontains $MACAddress)){return $false}
            if($ProcessorCount -and ($vmObj.ProcessorCount -ne $ProcessorCount)){return $false}
            if($MaximumMemory -and ($vmObj.MemoryMaximum -ne $MaximumMemory)){return $false}
            if($MinimumMemory -and ($vmObj.MemoryMinimum -ne $MinimumMemory)){return $false}

            return $true
        }
        else {return $false}
    }
    catch [System.Management.Automation.ActionPreferenceStopException]
    {
        ($Ensure -eq 'Absent')
    }
}

#region Helper function

function SetVMState
{
    param
    (
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter(Mandatory)]
        [ValidateSet("Running","Paused","Off")]
        [String]$State,

        [Boolean]$WaitForIP
    )

    switch ($State)
    {
        'Running' {
            $oldState = (Get-VM -Name $Name).State
            # If VM is in paused state, use resume-vm to make it running
            if($oldState -eq "Paused"){Resume-VM -Name $Name}
            # If VM is Off, use start-vm to make it running
            elseif ($oldState -eq "Off"){Start-VM -Name $Name}
            
            if($WaitForIP) { Get-VMIPAddress -Name $Name -Verbose }
        }
        'Paused' {if($oldState -ne 'Off'){Suspend-VM -Name $Name}}
        'Off' {Stop-VM -Name $Name -Force -WarningAction SilentlyContinue}
    }
}

function ChangeVMProperty
{
    param
    (
        [Parameter(Mandatory)]
        [String]$Name,

        [Parameter(Mandatory)]
        [String]$VMCommand,

        [Parameter(Mandatory)]
        [Hashtable]$ChangeProperty,

        [Boolean]$WaitForIP,

        [Boolean]$RestartIfNeeded
    )

    $vmObj = Get-VM -Name $Name
    if($vmObj.state -ne "Off" -and $RestartIfNeeded)
    { 
        SetVMState -Name $Name -State Off
        &$VMCommand -Name $Name @ChangeProperty

        # Can not move a off VM to paused, but only to running state
        if($vmObj.state -eq "Running")
        {
            SetVMState -Name $Name -State Running -WaitForIP $WaitForIP
        }

        Write-Verbose -Message "VM $Name now has correct properties."

        # Cannot make a paused VM to go back to Paused state after turning Off
        if($vmObj.state -eq "Paused")
        {
            Write-Warning -Message "VM $Name state will be OFF and not Paused"
        }
    }
    elseif($vmObj.state -eq "Off")
    {
        &$VMCommand -Name $Name @ChangeProperty 
        Write-Verbose -Message "VM $Name now has correct properties."
    }
    else
    {
        Write-Error -Message "Can not change properties for VM $Name in $($vmObj.State) state unless RestartIfNeeded is set to true"
    }
}

function Get-VMIPAddress
{
    param
    (
        [Parameter(Mandatory)]
        [string]$Name
    )

    while((Get-VMNetworkAdapter -VMName $Name).ipaddresses.count -lt 2)
    {
        Write-Verbose -Message "Waiting for IP Address for VM $Name ..." -Verbose
        Start-Sleep -Seconds 3;
    }
}

#endregion

Export-ModuleMember -Function *-TargetResource

