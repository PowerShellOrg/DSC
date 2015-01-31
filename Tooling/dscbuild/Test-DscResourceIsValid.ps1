function Test-DscResourceIsValid {
    [cmdletbinding(SupportsShouldProcess=$true)]
    param ()

    Add-DscBuildParameter -Name TestedModules -value @()

    if ( Test-BuildResource ) {
        if ($pscmdlet.shouldprocess("modules from $($script:DscBuildParameters.SourceResourceDirectory)")) {
            if ($script:DscBuildParameters.ModulesToPublish.Count -gt 0)
            {
                $AllResources = Get-DscResource | Where-Object {$_.ImplementedAs -like 'PowerShell'}

                Get-ChildItem -Path $script:DscBuildParameters.SourceResourceDirectory -Directory |
                Where Name -in $script:DscBuildParameters.ModulesToPublish |
                Assert-DscModuleResourceIsValid
            }
        }
    }
}

function Assert-DscModuleResourceIsValid
{
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline)]
        [IO.FileSystemInfo]
        $InputObject
    )

    begin
    {
        Write-Verbose "Testing for valid resources."
        $FailedDscResources = @()
    }

    process
    {
        $FailedDscResources += Get-FailedDscResource -AllModuleResources (Get-DscResourceForModule -InputObject $InputObject)
    }

    end
    {
        if ($FailedDscResources.Count -gt 0)
        {
            Write-Verbose "Found failed resources."
            foreach ($resource in $FailedDscResources)
            {

                Write-Warning "`t`tFailed Resource - $($resource.Name) ($($resource.ParentPath))"
            }

            throw "One or more resources is invalid."
        }
    }
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
        Write-Verbose "$Name does not contain any testable resources."
    }

    # We still want to deploy modules that have no testeable resources; they may contain
    # resources that are implemented as binary, or with PowerShell Classes in v5, etc.
    $script:DscBuildParameters.TestedModules += $InputObject.FullName

    $ResourcesInModule
}

function Get-FailedDscResource
{
    [cmdletbinding()]
    param ($AllModuleResources)

    foreach ($resource in $AllModuleResources)
    {
        if ($resource.Path)
        {
            $resourceNameOrPath = Split-Path $resource.Path -Parent
        }
        else
        {
            $resourceNameOrPath = $resource.Name
        }

        if (-not (Test-cDscResource -Name $resourceNameOrPath))
        {
            Write-Warning "`tResources $($_.name) is invalid."
            $resource
        }
    }
}
