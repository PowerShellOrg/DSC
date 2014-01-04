function Publish-DscResource
{
    param (
        [parameter()]
        [string]$Path,
        [parameter()]
        [string]$Destination,
        [parameter()]
        [switch]
        $SkipResourceCheck
    )
    end
    {
        $ResourceModules = @()
        if ($SkipResourceCheck)
        {
            Write-Verbose "Who needs validity checks?"
            Write-Verbose "  Testing in production is the only way to roll!"
            $ResourceModules += Dir $path -Directory 
        }
        else
        {                
            Write-Verbose "Checking Module Validity"
            $ResourceModules += Dir $path -Directory |
                Where-DscResource -IsValid -verbose 
        }

        $ResourceModules |      
            New-DscZipFile -Force | 
            Where-DscResource -Changed -Destination $Destination -verbose |
            Move-Item -Destination $Destination -Force -PassThru |
            New-DscChecksumFile
    }        
}