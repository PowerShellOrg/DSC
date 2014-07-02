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
        [alias('IsValid')]
        $CheckIfIsValid
    )
    begin
    {
        if ($CheckIfIsValid)
        {
            $AllResources = Get-DscResource | 
                Where-Object {$_.implementedas -like 'PowerShell'}

            Add-DscBuildParameter -Name TestedModules -value @()
        }
    }
    process
    {
        Write-Verbose "Checking $($inputobject.Name)."
        if ( $CheckIfIsValid -and (Test-DscModuleResourceIsValid @psboundparameters)  )
        {
             $InputObject
        }
    }
}

function Test-DscModuleResourceIsValid
{
    [cmdletbinding()]
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

    Write-Verbose "Testing for valid resources."
    $FailedDscResources = Get-FailedDscResource -AllModuleResources (Get-DscResourceForModule -InputObject $InputObject)

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
    param ($InputObject)

    $Name = $inputobject.Name
    Write-Verbose "Retrieving all resources and filtering for $Name."

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
    else {
        $script:DscBuildParameters.TestedModules += $InputObject.FullName
    }
    $ResourcesInModule
}

function Get-FailedDscResource
{
    [cmdletbinding()]
    param ($AllModuleResources)

    foreach ($resource in $AllModuleResources)
    {
        if (-not (Test-cDscResource -Name $Resource.Name))        
        {            
            Write-Warning "`tResources $($_.name) is invalid."  
            $resource
        }
    }
}

