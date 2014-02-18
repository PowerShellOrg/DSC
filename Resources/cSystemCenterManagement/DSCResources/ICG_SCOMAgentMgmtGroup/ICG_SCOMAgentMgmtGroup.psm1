#######################################################################
# OMAgentMgmtGroup DSC Resource
# DSC Resource to manage SCOM 2012 Agent Management Group settings.
# 201401127 - Joe Thompson, Infront Consulting Group
#######################################################################

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
	param
	(	
		[parameter(Mandatory)]
		[String] $ManagementGroupName,
		[parameter(Mandatory)]
	        [String] $ManagementServerName
  	)

	Try { $objCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg }     
	
	Catch { Throw "Monitoring Agent not installed." }

        $objMGs = $objCfg.GetManagementGroups() | %{$_.managementGroupName}        
	
	If ($objMGs -contains $ManagementGroupName) 
	{
        	$objMG = $objCfg.GetManagementGroup($ManagementGroupName)
        	$returnValue = @{
			ManagementGroupName = $objMG.ManagementGroupName
            		ManagementServerName = $objMG.ManagementServer
		}
	}
    	Else
    	{
        	$returnValue = @{
            		ManagementGroupName = $null
            		ManagementServerName = $null
	        }
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
        [ValidateSet("Present", "Absent")]        [String] $Ensure = "Present",		        [parameter(Mandatory)]		[String] $ManagementGroupName,        [parameter(Mandatory)]        [String] $ManagementServerName
  	)

Try    {        $objCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg    }     catch     {        throw "Monitoring Agent not installed."    }        $objMGs = $objCfg.GetManagementGroups() | %{$_.managementGroupName}        If ($objMGs -contains $ManagementGroupName)     {        If ($Ensure -eq "Absent")        {            Write-Verbose -Message "Monitoring Agent should not report to $ManagementGroupName, removing..."            $objCfg.RemoveManagementGroup($ManagementGroupName)             }    }    Else    {        If ($Ensure -eq "Present")        {            Write-Verbose -Message "Monitoring Agent is not reporting to $ManagementGroupName, adding it..."            $objCfg.AddManagementGroup($ManagementGroupName, $ManagementServerName, 5723)        }    } }             

#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]    [OutputType([System.Boolean])]
	param
	(	
        [ValidateSet("Present", "Absent")]        [String] $Ensure = "Present",
		[parameter(Mandatory)]		[String] $ManagementGroupName,        [parameter(Mandatory)]        [String] $ManagementServerName
  	)

   
    Write-Verbose -Message "Checking if Monitoring Agent reports to $ManagementGroupName Management Group"

    Try    {        $objCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg    }     catch     {        throw "Monitoring Agent not installed."    }        $objMGs = $objCfg.GetManagementGroups() | %{$_.managementGroupName}        If ($objMGs -contains $ManagementGroupName)     {        If ($Ensure -eq "Present")        {            Write-Verbose -Message "Monitoring Agent is alreadying reporting to $ManagementGroupName Management Group."            Write-Verbose -Message "Management Server for $ManagementGroupName is $ManagementServerName"            return $true        }        Write-Verbose -Message "$ManagementGroupName Management Group will be removed from Monitoring Agent."        return $false    }    Else    {           If ($Ensure -eq "Absent")        {            Write-Verbose -Message "Monitoring Agent doesn't need Management Group"            return $true        }        Write-Verbose -Message "$ManagementGroupName Management Group is missing from Monitoring Agent."        return $false    }        
}

       

Export-ModuleMember -Function *-TargetResource