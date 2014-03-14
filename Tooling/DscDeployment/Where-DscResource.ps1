function Where-DscResource
{
    param (
        [parameter(ValueFromPipeline)]
        [IO.FileSystemInfo]
        $InputObject,    
        [parameter()]
        [string]
        $Destination, 
        [switch]
        [alias('Changed')]
        $CheckIfChanged,
        [switch]
        [alias('IsValid')]
        $CheckIfIsValid
    )
    begin
    {
        if ($CheckIfIsValid)
        {
            $AllResources = Get-DscResource | 
                Where-Object {$_.implementedas -like 'PowerShell'}
        }
    }
    process
    {
        if ( ($CheckIfChanged -and (Test-ZippedModuleChanged)) -or
               ($CheckIfIsValid -and (Test-DscModuleResourceIsValid))  )
        {
             $InputObject
        }
    }
}


function Test-ZippedModuleChanged
{
    [cmdletbinding()]
    param ()
    Write-Verbose "Attempting to check if a resource has changed."
    $DestModule = join-path $Destination $inputobject.name
    if (Test-path $DestModule)
    {            
        Write-Verbose "There was an existing version of $($inputobject.Name)."
        $newhash = (Get-FileHash -path $inputobject.fullname).hash 
        $oldhash = (Get-FileHash -path $DestModule).hash 
        if ($newhash -ne $oldhash)
        {
            Write-Verbose "Existing version of $($inputobject.Name) was different."
            return $true
        }
        else
        {
            Write-Verbose "Existing version of $($inputobject.Name) matches the current."
            return $false
        }                            
    }
    else
    {
        Write-Verbose "No previous version of $($InputObject.Name)."
        return $true
    }
}

function Test-DscModuleResourceIsValid
{
    [cmdletbinding()]
    param ()    
    
    Write-Verbose "Retrieving all resources and filtering for $($InputObject.Name)."
    $AllModuleResources = Get-DscResourceForModule -Name $InputObject.Name
    
    Write-Verbose "Testing for valid resources."
    $FailedDscResources = Get-FailedDscResource

    if ($FailedDscResources)
    {
        Write-Verbose "Found failed resources."
        foreach ($resource in $FailedDscResources)
        {
            Write-Warning "`t`tFailed Resource - $($resource.Name)"
        }
        throw "Fix invalid resources in $($InputObject.Name)."
    }
    return $true
}

function Get-DscResourceForModule
{
    [cmdletbinding()]
    param ([string]$Name)

    Write-Verbose "Checking Resources in $Name."
    $ResourcesInModule = $AllResources | 
        Where-Object { 
            Write-Verbose "`tChecking for $($_.name) in $name."
            $_.module -like $name 
        } |
        ForEach-Object { 
            Write-Verbose "`t$Name contains $($_.Name)."                 
            $_ 
        } 
    if ($ResourcesInModule.count -eq 0)
    {
        Write-Warning "$Name does not contain any resources."
    }
    $ResourcesInModule
}

function Get-FailedDscResource
{
    [cmdletbinding()]
    param ()

    foreach ($resource in $AllModuleResources)
    {
        if (-not (Test-cDscResource -Name $Resource.Name -Verbose))        
        {            
            Write-Warning "`tResources $($_.name) is invalid."  
            $resource
        }
    }
}