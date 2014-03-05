data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create website {0}
SetTargetResourceUnInstallwhatIfMessage=Trying to remove website {0}
WebsiteNotFoundError=The requested website {0} is not found on the target machine.
WebsiteDiscoveryFailureError=Failure to get the requested website {0} information from the target machine.
WebsiteCreationFailure=Failure to successfully create the website {0} .
WebsiteUpdateFailureError=Failure to successfully update the website {0}.
WebsiteRemovalFailureError=Failure to successfully remove the website {0} .
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or Website on the target machine.
# It gives the Website info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,

        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",

        [string]$ApplicationPool,

        [string[]]$BindingInfo,

        [string[]]$Protocol
    )

        $getTargetResourceResult = $null;

	    $parameters = $psboundparameters.Remove("Ensure");

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        $Website = Get-Website -Name $Name

        $Result = ValidateWebsite $Website $Name;

        # Get properties for the website
        if($Website.Collection.Count -eq 1)
        {
            $ensureResult = "Present";
            [PSObject[]] $Protocol
            [PSObject[]] $Bindings

            $Protocol = $Website.bindings.Collection.protocol
            $Bindings = $Website.bindings.Collection.bindingInformation
        }
        else
        {
            $ensureResult = "Absent";
        }
        # Add all Website properties to the hash table
        $getTargetResourceResult = @{
    	                                Name = $Website.Name; 
                                        Ensure = $ensureResult;
                                        PhysicalPath = $Website.physicalPath;
                                        State = $Website.state;
                                        ID = $Website.id;
                                        ApplicationPool = $Website.applicationPool;
                                        Protocol = $Protocol;
                                        BindingInfo = $Bindings.Split(':');
                                    }
  
        $getTargetResourceResult;
}


# The Set-TargetResource cmdlet is used to create, delete or configuure a website on the target machine. 
function Set-TargetResource 
{
    [CmdletBinding()]
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,

        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",

        [string]$ApplicationPool,

        [string[]]$BindingInfo,

        [string[]]$Protocol
    )
 
    $getTargetResourceResult = $null;

    if($Ensure -eq "Present")
    {
        #Remove Ensure from parameters as it is not needed to create new website
        $Result = $psboundparameters.Remove("Ensure");
        #Remove State parameter form website. Will start the website after configuration is complete
        $Result = $psboundparameters.Remove("State");

        #Remove bindings from parameters if they exist
        #Bindings will be added to site using separate cmdlet
        $Result = $psboundparameters.Remove("Protocol");
        $Result = $psboundparameters.Remove("BindingInfo");

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }
        $website = get-website $Name

        if($website -ne $null)
        {
            #update parameters as required

            $UpdateNotRequired = $true

            #Update Physical Path if required
            if(ValidateWebsitePath -Name $Name -PhysicalPath $PhysicalPath)
            {
                $UpdateNotRequired = $false
                Set-ItemProperty "IIS:\Sites\$Name" -Name physicalPath -Value $PhysicalPath -ErrorAction Stop

                Write-Verbose("Physical path for website $Name has been updated to $PhysicalPath");
            }

            #Update Bindings if required
            if(ValidateWebsiteBindings -Name $Name -DesiredBindings $BindingInfo -DesiredProtocol $Protocol)
            {
                $UpdateNotRequired = $false
                #Update Bindings
                UpdateBindings -Name $Name -BindingInfo $BindingInfo -Protocol $Protocol -ErrorAction Stop

                Write-Verbose("Bindings for website $Name have been updated to protocol($Protocol), binding($BindingInfo)");
            }

            #Update Application Pool if required
            if(($website.applicationPool -ne $ApplicationPool) -and ($ApplicationPool -ne ""))
            {
                $UpdateNotRequired = $false
                Set-ItemProperty IIS:\Sites\$Name -Name applicationPool -Value $ApplicationPool -ErrorAction Stop

                Write-Verbose("Application Pool for website $Name has been updated to $ApplicationPool")
            }

            #Update State if required
            if($website.state -ne $State -and $State -ne "")
            {
                $UpdateNotRequired = $false
                if($State -eq "Started")
                {
                    Start-Website -Name $Name
                }
                else
                {
                    Stop-Website -Name $Name
                }

                Write-Verbose("State for website $Name has been updated to $State");
            }

            if($UpdateNotRequired)
            {
                Write-Verbose("Website $Name already exists and properties do not need to be udpated.");
            }
            

        }
        else #Website doesn't exist so create new one
        {
            $Website = New-Website @psboundparameters
            $Result = Stop-Website $Website.name -ErrorAction Stop
            
            if($website -ne $null)
            {

                #Clear default bindings if new bindings defined and are different
                if(ValidateWebsiteBindings -Name $Name -DesiredBindings $BindingInfo -DesiredProtocol $Protocol)
                {
                    UpdateBindings -Name $Name -BindingInfo $BindingInfo -Protocol $Protocol -ErrorAction Stop
                }

                Write-Verbose("successfully created website $Name")
                
                #Start site if required
                if($State -eq "Started")
                {
                    #Wait 1 sec for bindings to take effect
                    #I have found that starting the website results in an error if it happens to quickly
                    Start-Sleep -s 1
                    Start-Website -Name $Name -ErrorAction Stop
                }

                Write-Verbose("successfully started website $Name")
            }
            else
            {
                $errorId = "WebsiteCreationFailure"; 
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                $errorMessage = $($LocalizedData.FeatureInstallationFailureError) -f ${Name} ;
                $exception = New-Object System.InvalidOperationException $errorMessage ;
                $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                $PSCmdlet.ThrowTerminatingError($errorRecord);
            }
        }    
    }
    else #Ensure is set to "Absent" so remove website 
    {
        $Result = $psboundparameters.Remove("Ensure")
        $Result = $psboundparameters.Remove("PhysicalPath")

        Remove-website @psboundparameters -ErrorAction Stop
        
        Write-Verbose("successfully removed Website $Name.")
        
    }
}


# The Test-TargetResource cmdlet is used to validate if the role or feature is in a state as expected in the instance document.
function Test-TargetResource 
{
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,

        [ValidateSet("Started", "Stopped")]
        [string]$State = "Started",

        [string]$ApplicationPool,

        [string[]]$BindingInfo,

        [string[]]$Protocol
    )
 
    $DesiredConfigurationMatch = $true;

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    $website = Get-Website -Name $Name -ErrorAction SilentlyContinue
    $Stop = $true

    Do
    {
        #Check Ensure
        if(($Ensure -eq "Present" -and $website -eq $null) -or ($Ensure -eq "Absent" -and $website -ne $null))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("The Ensure state for website $Name does not match the desired state.");
            break
        }

        #Check Physical Path property
        if(ValidateWebsitePath -Name $Name -PhysicalPath $PhysicalPath)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("Physical Path of Website $Name does not match the desired state.");
            break
        }

        #Check State
        if($website.state -ne $State -and $State -ne $null)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("The state of Website $Name does not match the desired state.");
            break
        }

        #Check Application Pool property 
        if(($ApplicationPool -ne "") -and ($website.applicationPool -ne $ApplicationPool))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("Application Pool for Website $Name does not match the desired state.");
            break
        }

        #Check Binding properties
        if(ValidateWebsiteBindings -Name $Name -DesiredBindings $BindingInfo -DesiredProtocol $Protocol)
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("Bindings for website $Name do not mach the desired state.");
            break
        }

        $Stop = $false
    }
    While($Stop)   

    $DesiredConfigurationMatch;
}

#region HelperFunctions
# ValidateWebsite is a helper function used to validate the results 
function ValidateWebsite 
{
    param 
    (
        [object] $Website,

        [string] $Name
    )

    # If a wildCard pattern is not supported by the website provider. 
    # Hence we restrict user to request only one website information in a single request.
    if($Website.Count-gt 1)
    {
        $errorId = "WebsiteDiscoveryFailure"; 
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $errorMessage = $($LocalizedData.WebsiteUpdateFailureError) -f ${Name} 
        $exception = New-Object System.InvalidOperationException $errorMessage 
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }
}

# Helper function used to validate website path
function ValidateWebsitePath
{
    param
    (
        [string] $Name,

        [string] $PhysicalPath
    )

    $PathNeedsUpdating = $false

    if((Get-ItemProperty "IIS:\Sites\$Name" -Name physicalPath) -ne $PhysicalPath)
    {
        $PathNeedsUpdating = $true
    }

    $PathNeedsUpdating

}

# Helper function used to validate website bindings
function ValidateWebsiteBindings
{
    param
    (
        [parameter()]
        [string] 
        $Name,

        [parameter()]
        [string[]] 
        $DesiredBindings = "*:80:",

        [parameter()]
        [string[]] 
        $DesiredProtocol = "http"
    )
    $BindingNeedsUpdating = $false

    $ActualBindingInfo = Get-ItemProperty "IIS:\Sites\$Name" -Name Bindings

    if($DesiredBindings.Count -ne $DesiredProtocol.Count)
    {
        $errorId = "WebsiteUpdateFailure"; 
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
        $errorMessage = $($LocalizedData.WebsiteUpdateFailureError) -f ${Name} 
        $exception = New-Object System.InvalidOperationException $errorMessage 
        $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord);
    }
    else
    {
        for($i=0; $i -lt $DesiredProtocol.Count; $i++)
        {
            $BindingExists = $false
            foreach($ActualBinding in $ActualBindingInfo)
            {
                if(($ActualBinding.Collection.protocol -eq $DesiredProtocol[$i]) -and ($ActualBinding.Collection.bindingInformation -eq $DesiredBindings[$i]))
                {
                    $BindingExists = $true
                    break
                }
            }

            if(!$BindingExists)
            {
                $BindingNeedsUpdating = $true
                break
            }
        }

        $BindingNeedsUpdating
    }
}

function UpdateBindings
{
    param
    (
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [parameter()]
        [string[]] 
        $BindingInfo = "*:80:",

        [parameter()]
        [string[]] 
        $Protocol = "http"
    )
    #Need to clear the bindings before we can create new ones
    Clear-ItemProperty IIS:\Sites\$Name -Name bindings

    for($i=0; $i -lt $Protocol.Count; $i++)
    {
        $Binding = $BindingInfo[$i].Split(":")
        $IPAddress = $Binding[0]
        $Port = $Binding[1]
        $HostHeader = $Binding[2]
                    
        $bindingParams = @{}
        $bindingParams.Add('-Name', $Name)
        $bindingParams.Add('-Port', $Port)
                    
        #Set IP Address parameter
        if($IPAddress -ne $null)
        {
            $bindingParams.Add('-IPAddress', $IPAddress)
        }
        else # Default to any/all IP Addresses
        {
            $bindingParams.Add('-IPAddress', '*')
        }

        #Set protocol parameter
        if($Protocol-ne $null)
        {
            $bindingParams.Add('-Protocol', $Protocol[$i])
        }
        else #Default to Http
        {
            $bindingParams.Add('-Protocol', 'http')
        }

        #Set Host parameter if it exists
        if($HostHeader-ne $null > 0){$bindingParams.Add('-HostHeader', $HostHeader)}


        New-WebBinding @bindingParams -ErrorAction Stop
    }
}
#endregion

Export-ModuleMember -Function *-TargetResource