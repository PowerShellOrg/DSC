
#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
	param
	(	
        [parameter(Mandatory)]
        [string] $Name,

        [string] $DomainName,

        [PSCredential]$Credential,

	[string] $WorkGroupName
  	)

    $convertToCim = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$Credential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
    $returnValue = @{
		Name = $env:COMPUTERNAME
        DomainName =(gwmi WIN32_ComputerSystem).Domain
		Credential = [ciminstance]$convertToCim
		WorkGroupName= (gwmi WIN32_ComputerSystem).WorkGroup
	}

	$returnValue
}

######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource
{
	param
	(	
        [parameter(Mandatory)]
        [string] $Name,
	
        [string] $DomainName,
        
        [PSCredential]$Credential,

	    [string] $WorkGroupName


	)
    ValidateDomainWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName
   
	$currName = $env:COMPUTERNAME

    if($Credential)
    {
        if($DomainName)
        {
            $currentMachineDomain = (gwmi win32_computersystem).Domain
            if($DomainName -eq $currentMachineDomain)
            {
                #new computer name, stay on the same domain
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force 
                Write-Verbose -Message "Renamed computer to $Name"
            }
            else
            {
                if($Name -ne $currName)
                {
                    #New computer name, join to domain
                    Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -Force
                    Write-Verbose -Message "Renamed computer to $Name and added to the domain $DomainName"
                }
                else
                {
                    #Same computer name, join to domain
                    Add-Computer -DomainName $DomainName -Credential $Credential -Force
                    Write-Verbose -Message "Added computer to Domain $DomainName"
                }
            }
        }
        elseif ($WorkGroupName)
        {
            $currentMachineWorkgroup = (gwmi win32_computersystem).WorkGroup
            if($WorkGroupName -eq $currentMachineWorkgroup)
            {
                #new computer name, stay on the same workgroup
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to $Name"
            }
            else
            {
                if($Name -ne $currName)
                {
                    #New computer name, join to workgroup
                    Add-Computer -NewName $Name -Credential $Credential -WorkgroupName $WorkGroupName -Force 
                    Write-Verbose -Message "Renamed computer to $Name and addded computer to workgroup $WorkGroupName"
                }
                else
                {
                    #same computer name, join to workgroup
                    Add-Computer -WorkGroupName $WorkGroupName -Credential $Credential -Force    
                    Write-Verbose -Message "Added computer to workgroup $WorkGroupName"
                }           
            }
        }
        #a user neither provides domain nor workgroup
        elseif($Name -ne $currName)
        {
            #Check if the computer is domain-joined or part of a workgroup
            $isMachineInDomain = (Get-WmiObject win32_computersystem).PartOfDomain
            if($isMachineInDomain)
            {
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force 
                Write-Verbose -Message "Renamed computer to $Name"
            }
            else
            {
                Rename-Computer -NewName $Name -Force
                Write-Verbose -Message "Renamed computer to $Name"
            }
        }                 
    }
    
    # must be non domain scenario - change the machine name in the same workgroup or change workgroup name or both
    else
    {
        if($DomainName)
        {
            throw "Need to specify credentials with domain"
        }
        if($WorkGroupName)
        {
            
            if($WorkGroupName -eq (Get-WmiObject win32_computersystem).Workgroup)
            {
                # Same workgroup, new computer name
                Rename-Computer -NewName $Name -force
                Write-Verbose -Message "Renamed computer to $Name"
            }
            else
            {
                if($name -ne $env:COMPUTERNAME)
                {
                    #New workgroup, new name
                    Add-Computer -WorkgroupName $WorkGroupName -NewName $Name
                }
                else
                {
                    #New workgroup, same name
                    Add-Computer -WorkgroupName $WorkGroupName
                }

                Write-Verbose -Message "Added computer to workgroup $WorkGroupName"
            }
        }
        else
        {
            if($Name -ne $env:COMPUTERNAME)
            {
                #Only if new name is different from the current name
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to $Name"
            }
        }
    }
        
    
    
    # Tell the DSC Engine to restart the machine
    $global:DSCMachineStatus = 1
}

#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
	[CmdletBinding()]
	param
	(
        [parameter(Mandatory)]
        [string] $Name,
        
        [PSCredential]$Credential,
        
        [string] $DomainName,

	    [string] $WorkGroupName
	)
    
    Write-Verbose -Message "Checking if computer name is $Name"

    $testResult= ($Name -eq $env:COMPUTERNAME)
    ValidateDomainWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName
    $computerSystem =get-WmiObject -Class Win32_ComputerSystem
    if($DomainName)
    {
        if(!($Credential))
        {
            throw "Need to specify credentials with domain"
        }
        Write-Verbose -Message "Checking if domain name is $DomainName"
        $testResult= $testResult -and ($DomainName -eq $computerSystem.Domain)
    }
    elseif($WorkGroupName)
    {
        Write-Verbose -Message "Checking if workgroup name is $WorkGroupName"
        $testResult= $testResult -and ($WorkGroupName -eq $computerSystem.WorkGroup)
    }
    $testResult
}
#######################################################################
# Validation functions (Not exported)
#######################################################################

function ValidateDomainWorkGroup
{
	param($DomainName,$WorkGroupName)
	if($DomainName -and $WorkGroupName)
	{
		throw "Only one of either the domain name or the workgroup name can be set! Please edit the configuration to ensure that only one of these properties have a value."

	}
}


Export-ModuleMember -Function *-TargetResource

