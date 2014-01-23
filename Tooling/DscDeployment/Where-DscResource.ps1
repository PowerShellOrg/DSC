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
        $Changed,
        [switch]
        $IsValid
    )
    begin
    {
        if ($IsValid)
        {
            $AllResources = Get-DscResource
        }
    }
    process
    {
        
        if ($Changed)
        {
            $DestModule = join-path $Destination $inputobject.name
            if (Test-path $DestModule)
            {            
                Write-Verbose "There was an existing version of $($inputobject.Name)."
                $newhash = (Get-FileHash -path $inputobject.fullname).hash 
                $oldhash = (Get-FileHash -path $DestModule).hash 
                if ($newhash -ne $oldhash)
                {
                    Write-Verbose "Existing version of $($inputobject.Name) was different."
                    $InputObject
                }
                else
                {
                    Write-Verbose "Existing version of $($inputobject.Name) matches the current."
                }                            
            }
            else
            {
                Write-Verbose "No previous version of $($InputObject.Name)."
                $InputObject
            }
        }

        if ($IsValid)
        {
            $Name = $_.Name
            Write-Verbose "Checking Resources in $Name."
        
            $AllModuleResources = @()
            $AllModuleResources = @($AllResources | 
                Where-Object { 
                    Write-Verbose "`tChecking for $($_.name) in $name."
                    $_.module -like $name 
                } |
                ForEach-Object { 
                    Write-Verbose "`t$Name contains $($_.Name)."                 
                    $_ 
                } )

            if ($AllModuleResources.count -gt 0)
            {
                $GoodResources = $AllModuleResources |
                    Where-Object {
                        Write-Verbose "Testing $($_.Name)"
                        Test-DscResource -Name $_.Name  -Verbose
                    }
                
            
        
                $MatchingResources = @(Compare-Object $AllModuleResources $GoodResources -ExcludeDifferent -IncludeEqual)
                foreach ($resource in $MatchingResources)
                {
                    Write-Verbose " "
                }
                if ($MatchingResources.count -eq $AllModuleResources.count)
                {
                    Write-Verbose "Resources in $Name are valid."
                    Write-Output $InputObject
                }
                else
                {
                    Write-Warning "Valid resources in $Name do not match all the resources in "
                    $AllModuleResources | 
                        Where-Object {$GoodResources -notcontains $_} |
                        ForEach-Object { Write-Warning "`tResources $($_.name) is invalid." }
                    throw "Fix invalid resources in $Name."
                }
            }
            else
            {
                Write-Warning "$Name does not contain any resources."
            }
        }

    }
}
