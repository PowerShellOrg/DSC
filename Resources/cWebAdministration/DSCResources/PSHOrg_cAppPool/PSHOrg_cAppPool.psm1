data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
SetTargetResourceInstallwhatIfMessage=Trying to create AppPool "{0}".
SetTargetResourceUnInstallwhatIfMessage=Trying to remove AppPool "{0}".
AppPoolNotFoundError=The requested AppPool "{0}" is not found on the target machine.
AppPoolDiscoveryFailureError=Failure to get the requested AppPool "{0}" information from the target machine.
AppPoolCreationFailureError=Failure to successfully create the AppPool "{0}".
AppPoolRemovalFailureError=Failure to successfully remove the AppPool "{0}".
AppPoolUpdateFailureError=Failure to successfully update the properties for AppPool "{0}".
AppPoolCompareFailureError=Failure to successfully compare properties for AppPool "{0}".
AppPoolStateFailureError=Failure to successfully set the state of the AppPool {0}.
'@
}

# The Get-TargetResource cmdlet is used to fetch the status of role or AppPool on the target machine.
# It gives the AppPool info of the requested role/feature on the target machine.  
function Get-TargetResource 
{
    param 
    (   
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

        $getTargetResourceResult = $null;

        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }

        $AppPools = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

        if ($AppPools.count -eq 0) # No AppPool exists with this name.
        {
            $ensureResult = "Absent";
        }
        elseif ($AppPool.count -eq 1) # A single AppPool exists with this name.
        {
            $ensureResult = "Present"

            [xml] $PoolConfig
            $PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
            if($PoolConfig.add.processModel.userName){
                $AppPoolPassword = $PoolConfig.add.processModel.password | ConvertTo-SecureString
                $AppPoolCred = new-object -typename System.Management.Automation.PSCredential -argumentlist $PoolConfig.add.processModel.userName,$AppPoolPassword
            }
            else{
                $AppPoolCred =$null
            }

        }
        else # Multiple AppPools with the same name exist. This is not supported and is an error
        {
            $errorId = "AppPoolDiscoveryFailure"; 
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidResult
            $errorMessage = $($LocalizedData.AppPoolUpdateFailureError) -f ${Name} 
            $exception = New-Object System.InvalidOperationException $errorMessage 
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }

        # Add all Website properties to the hash table
        $getTargetResourceResult = @{
    	                                Name = $PoolConfig.add.name; 
                                        Ensure = $ensureResult;
                                        autoStart = $PoolConfig.add.autoStart;
                                        managedRuntimeVersion = $PoolConfig.add.managedRuntimeVersion;
                                        managedPipelineMode = $PoolConfig.add.managedPipelineMode;
                                        startMode = $PoolConfig.add.startMode;
                                        identityType = $PoolConfig.add.processModel.identityType;
                                        userName = $PoolConfig.add.processModel.userName;
                                        password = $AppPoolCred
                                        loadUserProfile = $PoolConfig.add.processModel.loadUserProfile;

                                    }
        
        return $getTargetResourceResult;
}


# The Set-TargetResource cmdlet is used to create, delete or configuure a website on the target machine. 
function Set-TargetResource 
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param 
    (       
        [ValidateSet("Present", "Absent")]
        [string]$Ensure = "Present",

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet("true","false")]
        [string]$autoStart = "true",

        [ValidateSet("v4.0","v2.0","")]
        [string]$managedRuntimeVersion = "v4.0",

        [ValidateSet("Integrated","Classic")]
        [string]$managedPipelineMode = "Integrated",

        [ValidateSet("AlwaysRunning","OnDemand")]
        [string]$startMode = "OnDemand",

        [ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
        [string]$identityType = "ApplicationPoolIdentity",

        [string]$userName,

        [System.Management.Automation.PSCredential]
        $Password,

        [ValidateSet("true","false")]
        [string]$loadUserProfile = "true"

    )
 
    $getTargetResourceResult = $null;

    if($Ensure -eq "Present")
    {
        #Remove Ensure from parameters as it is not needed to create new AppPool
        $Result = $psboundparameters.Remove("Ensure");


        # Check if WebAdministration module is present for IIS cmdlets
        if(!(Get-Module -ListAvailable -Name WebAdministration))
        {
            Throw "Please ensure that WebAdministration module is installed."
        }
        $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name

        if($AppPool -ne $null)
        {
            #update parameters as required

            $UpdateNotRequired = $true

            #get configuration of AppPool
            #[xml] $PoolConfig
            [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*

            #Update autoStart if required
            if($PoolConfig.add.autoStart -ne $autoStart){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart
            }

            #update managedRuntimeVersion if required
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion
            }
            #update managedPipelineMode if required
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode
            }
            #update startMode if required
            if($PoolConfig.add.startMode -ne $startMode){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode
            }
            #update identityType if required
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
            }
            #update userName if required
            if($identityType -eq "SpecificUser" -and $PoolConfig.add.processModel.userName -ne $userName){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName
            }
            #update password if required
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -eq $PoolConfig.add.processModel.password){
                    $UpdateNotRequired = $false
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword
                }

            }
            #update loadUserProfile if required
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $UpdateNotRequired = $false
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile
            }

            if($UpdateNotRequired)
            {
                Write-Verbose("AppPool $Name already exists and properties do not need to be udpated.");
            }
            

        }
        else #AppPool doesn't exist so create new one
        {
            try
            {
                New-WebAppPool $Name
		        Wait-Event -Timeout 5
                Stop-WebAppPool $Name
            
                #Configure settings that have been passed
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /autoStart:$autoStart

                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedRuntimeVersion:$managedRuntimeVersion
            
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /managedPipelineMode:$managedPipelineMode

                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /startMode:$startMode
            
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.identityType:$identityType
            
                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.userName:$userName
          
            #set password if required
                if($identityType -eq "SpecificUser" -and $Password){
                    $clearTextPassword = $Password.GetNetworkCredential().Password
                    & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.password:$clearTextPassword
                }

                & $env:SystemRoot\system32\inetsrv\appcmd.exe set apppool $Name /processModel.loadUserProfile:$loadUserProfile
            
                Write-Verbose("successfully created AppPool $Name")
                
                #Start site if required
                if($autoStart -eq "true")
                {
                    Start-WebAppPool $Name
                }

                Write-Verbose("successfully started AppPool $Name")
            }
            catch
            {
                $errorId = "AppPoolCreationFailure"; 
                $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                $errorMessage = $($LocalizedData.FeatureCreationFailureError) -f ${Name} ;
                $exception = New-Object System.InvalidOperationException $errorMessage ;
                $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

                $PSCmdlet.ThrowTerminatingError($errorRecord);
            }
        }    
    }
    else #Ensure is set to "Absent" so remove website 
    { 
        try
        {
            $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
            if($AppPool -ne $null)
            {
                Stop-WebAppPool $Name
                Remove-WebAppPool $Name
        
                Write-Verbose("Successfully removed AppPool $Name.")
            }
            else
            {
                Write-Verbose("AppPool $Name does not exist.")
            }
        }
        catch
        {
            $errorId = "AppPoolRemovalFailure"; 
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation;
            $errorMessage = $($LocalizedData.WebsiteRemovalFailureError) -f ${Name} ;
            $exception = New-Object System.InvalidOperationException $errorMessage ;
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null

            $PSCmdlet.ThrowTerminatingError($errorRecord);
        }
        
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

        [ValidateSet("true","false")]
        [string]$autoStart = "true",

        [ValidateSet("v4.0","v2.0","")]
        [string]$managedRuntimeVersion = "v4.0",

        [ValidateSet("Integrated","Classic")]
        [string]$managedPipelineMode = "Integrated",

        [ValidateSet("AlwaysRunning","OnDemand")]
        [string]$startMode = "OnDemand",

        [ValidateSet("ApplicationPoolIdentity","LocalSystem","LocalService","NetworkService","SpecificUser")]
        [string]$identityType = "ApplicationPoolIdentity",

        [string]$userName,

        [System.Management.Automation.PSCredential]
        $Password,

        [ValidateSet("true","false")]
        [string]$loadUserProfile = "true"
    )
 
    $DesiredConfigurationMatch = $true

    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw "Please ensure that WebAdministration module is installed."
    }

    $AppPool = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name
    if($AppPool){
        #get configuration of AppPool
        #[xml] $PoolConfig
        [xml]$PoolConfig = & $env:SystemRoot\system32\inetsrv\appcmd.exe list apppool $Name /config:*
    }
    $Stop = $true

    Do
    {
        #Check Ensure
        if(($Ensure -eq "Present" -and $AppPool -eq $null) -or ($Ensure -eq "Absent" -and $AppPool -ne $null))
        {
            $DesiredConfigurationMatch = $false
            Write-Verbose("The Ensure state for AppPool $Name does not match the desired state.");
            break
        }

        # Only check properties if $AppPool exists
        if ($AppPool -ne $null)
        {
            #Check autoStart
            if($PoolConfig.add.autoStart -ne $autoStart){
                $DesiredConfigurationMatch = $false
                Write-Verbose("autoStart of AppPool $Name does not match the desired state.");
                break
            }

            #Check managedRuntimeVersion 
            if($PoolConfig.add.managedRuntimeVersion -ne $managedRuntimeVersion){
                $DesiredConfigurationMatch = $false
                Write-Verbose("managedRuntimeVersion of AppPool $Name does not match the desired state.");
                break
            }
            #Check managedPipelineMode 
            if($PoolConfig.add.managedPipelineMode -ne $managedPipelineMode){
                $DesiredConfigurationMatch = $false
                Write-Verbose("managedPipelineMode of AppPool $Name does not match the desired state.");
                break
            }
            #Check startMode 
            if($PoolConfig.add.startMode -ne $startMode){
                $DesiredConfigurationMatch = $false
                Write-Verbose("startMode of AppPool $Name does not match the desired state.");
                break
            }
            #Check identityType 
            if($PoolConfig.add.processModel.identityType -ne $identityType){
                $DesiredConfigurationMatch = $false
                Write-Verbose("identityType of AppPool $Name does not match the desired state.");
                break
            }
            #Check userName 
            if($PoolConfig.add.processModel.userName -ne $userName){
                $DesiredConfigurationMatch = $false
                Write-Verbose("userName of AppPool $Name does not match the desired state.");
                break
            }
            #Check password 
            if($identityType -eq "SpecificUser" -and $Password){
                $clearTextPassword = $Password.GetNetworkCredential().Password
                if($clearTextPassword -eq $PoolConfig.add.processModel.password){
                    $DesiredConfigurationMatch = $false
                    Write-Verbose("Password of AppPool $Name does not match the desired state.");
                    break
                }

            }
            #Check loadUserProfile 
            if($PoolConfig.add.processModel.loadUserProfile -ne $loadUserProfile){
                $DesiredConfigurationMatch = $false
                Write-Verbose("loadUserProfile of AppPool $Name does not match the desired state.");
                break
            }
        }

        $Stop = $false
    }
    While($Stop)   

    return $DesiredConfigurationMatch
}