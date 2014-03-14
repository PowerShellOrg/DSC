function Publish-DscResource
{
    param (
        [parameter()]
        [string]$Path,
        [parameter()]
        [string]$Destination,
        [string[]]
        $ExcludedModules = ('cActiveDirectory',
                            'cComputerManagement', 
                            'cFailoverCluster', 
                            'cHyper-V', 
                            'cNetworking', 
                            'cPSDesiredStateConfiguration', 
                            'cSmbShare', 
                            'cSqlPs',
                            'cSystemCenterManagement',                            
                            'cWebAdministration', 
                            'Craig-Martin',
                            'rchaganti') ,
        [parameter()]
        [switch]
        $SkipResourceCheck
    )
    end
    {
        $ResourceModules = Dir $path -Directory | 
            Where-object { $ExcludedModules -notcontains $_.name }
        if ($SkipResourceCheck)
        {
            Write-Verbose "Who needs validity checks?"
            Write-Verbose "  Testing in production is the only way to roll!"            
        }
        else
        {                
            Write-Verbose "Checking Module Validity"
            $ResourceModules += $ResourceModules |
                Where-DscResource -IsValid -verbose 
        }

        #Update-ModuleMetadataVersion |      
        $ResourceModules |            
            New-DscZipFile -Force | 
            Where-DscResource -Changed -Destination $Destination -verbose |
            Move-Item -Destination $Destination -Force -PassThru |
            New-DscChecksumFile
    }        
}
