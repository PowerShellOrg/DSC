function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[ValidateSet("External","Internal","Private")]
		[String]$Type
	)

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    $switch = Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction SilentlyContinue

    @{
		Name              = $switch.Name
		Type              = $switch.SwitchType
		NetAdapterName    = $( if($switch.NetAdapterInterfaceDescription){
                              (Get-NetAdapter -InterfaceDescription $switch.NetAdapterInterfaceDescription).Name})
		AllowManagementOS = $switch.AllowManagementOS
		Ensure            = if($switch){'Present'}else{'Absent'}
		Id                = $switch.Id
		NetAdapterInterfaceDescription = $switch.NetAdapterInterfaceDescription
	}
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[ValidateSet("External","Internal","Private")]
		[String]$Type,

        [ValidateNotNullOrEmpty()]
		[String]$NetAdapterName,

		[Boolean]$AllowManagementOS,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)
    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    if($Ensure -eq 'Present')
    {
        $switch = (Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction SilentlyContinue)

        # If switch is present and it is external type, that means it doesn't have right properties (TEST code ensures that)
        if($switch -and ($switch.SwitchType -eq 'External'))
        {
            Write-Verbose -Message "Checking switch $Name NetAdapterInterface ..."
            if((Get-NetAdapter -Name $NetAdapterName).InterfaceDescription -ne $switch.NetAdapterInterfaceDescription)
            {
                Write-Verbose -Message "Removing switch $Name and creating with right netadapter ..."
                $switch | Remove-VMSwitch -Force
                $parameters = @{}
                $parameters["Name"] = $Name
                $parameters["NetAdapterName"] = $NetAdapterName
                if($AllowManagementOS){$parameters["AllowManagementOS"]=$AllowManagementOS}
                $null = New-VMSwitch @parameters
                Write-Verbose -Message "Switch $Name has right netadapter $NetAdapterName"
            }
            else
            {
                Write-Verbose -Message "Switch $Name has right netadapter $NetAdapterName"
            }

            Write-Verbose -Message "Checking switch $Name AllowManagementOS ..."
            if($PSBoundParameters.ContainsKey("AllowManagementOS") -and ($switch.AllowManagementOS -ne $AllowManagementOS))
            {
                Write-Verbose -Message "Switch $Name AllowManagementOS property is not correct"
                $switch | Set-VMSwitch -AllowManagementOS $AllowManagementOS
                Write-Verbose -Message "Switch $Name AllowManagementOS property is set to $AllowManagementOS"
            }
            else
            {
                Write-Verbose -Message "Switch $Name AllowManagementOS is correctly set"
            }
        }

        # If the switch is not present, create one
        else
        {
            Write-Verbose -Message "Switch $Name is not $Ensure."
            Write-Verbose -Message "Creating Switch ..."
            $parameters = @{}
            $parameters["Name"] = $Name
            if($NetAdapterName)
            {
                $parameters["NetAdapterName"] = $NetAdapterName
                if($AllowManagementOS)
                {
                    $parameters["AllowManagementOS"] = $AllowManagementOS
                }
            }
            else
            { 
                $parameters["SwitchType"] = $Type
            }
            
            $null = New-VMSwitch @parameters
            Write-Verbose -Message "Switch $Name is now $Ensure."
        }
    }
    # Ensure is set to "Absent", remove the switch
    else
    {
        Get-VMSwitch $Name -ErrorAction SilentlyContinue | Remove-VMSwitch -Force
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory)]
		[String]$Name,

		[parameter(Mandatory)]
		[ValidateSet("External","Internal","Private")]
		[String]$Type,

        [ValidateNotNullOrEmpty()]
		[String]$NetAdapterName,

		[Boolean]$AllowManagementOS,

		[ValidateSet("Present","Absent")]
		[String]$Ensure = "Present"
	)

    #region input validation

    # Check if Hyper-V module is present for Hyper-V cmdlets
    if(!(Get-Module -ListAvailable -Name Hyper-V))
    {
        Throw "Please ensure that Hyper-V role is installed with its PowerShell module"
    }

    If($Type -eq 'External' -and !($NetAdapterName))
    {
        Throw "For external switch type, NetAdapterName must be specified"
    }
    
    
    If($Type -ne 'External' -and $NetAdapterName)
    {
        Throw "For Internal or Private switch type, NetAdapterName should not be specified"
    }  
    #endregion

    try
    {
        # Check if switch exists
        Write-Verbose -Message "Checking if Switch $Name is $Ensure ..."
        $switch = Get-VMSwitch -Name $Name -SwitchType $Type -ErrorAction Stop

        # If switch exists
        if($switch)
        {
            Write-Verbose -Message "Switch $Name is Present"
            # If switch should be present, check the switch type
            if($Ensure -eq 'Present')
            {
                # If switch is the external type, check additional propeties
                if($switch.SwitchType -eq 'External')
                {
                    Write-Verbose -Message "Checking if Switch $Name has correct NetAdapterInterface ..."
                    if((Get-NetAdapter -Name $NetAdapterName -ErrorAction SilentlyContinue).InterfaceDescription -ne $switch.NetAdapterInterfaceDescription)
                    {
                        return $false
                    }
                    else
                    {
                        Write-Verbose -Message "Switch $Name has correct NetAdapterInterface"
                    }
                    
                    if($PSBoundParameters.ContainsKey("AllowManagementOS"))
                    {
                        Write-Verbose -Message "Checking if Switch $Name has AllowManagementOS set correctly..."
                        if(($switch.AllowManagementOS -ne $AllowManagementOS))
                        {
                            return $false
                        }
                        else
                        {
                            Write-Verbose -Message "Switch $Name has AllowManagementOS set correctly"
                        }
                    }
                    return $true
                }
                else
                {
                    return $true
                }
            }
            # If switch should be absent, but is there, return $false
            else
            {
                return $false
            }
        }
    }

    # If no switch was present
    catch [System.Management.Automation.ActionPreferenceStopException]
    {
        Write-Verbose -Message "Switch $Name is not Present"
        return ($Ensure -eq 'Absent')
    }
}

Export-ModuleMember -Function *-TargetResource

