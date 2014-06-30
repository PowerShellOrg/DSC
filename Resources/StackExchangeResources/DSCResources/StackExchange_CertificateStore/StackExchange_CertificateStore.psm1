

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    $Ensure = 'Present'

    if (Test-TargetResource @PSBoundParameters)
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $Configuration = @{
        Name = $Name
        Path = $Path
        Location = $Location
        Store = $Store
        Ensure = $Ensure
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $CertificateBaseLocation = "cert:\$Location\$Store"
    
    if ($Ensure -like 'Present')
    {        
        Write-Verbose "Adding $path to $CertificateBaseLocation."
        Import-PfxCertificate -CertStoreLocation $CertificateBaseLocation -FilePath $Path 
    }
    else
    {
        $CertificateLocation = Join-path $CertificateBaseLocation $Name
        Write-Verbose "Removing $CertificateLocation."
        dir $CertificateLocation | Remove-Item -Force -Confirm:$false   
    }
}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,
        [parameter()]
        [ValidateSet('LocalMachine','CurrentUser')]
        [string]
        $Location = 'LocalMachine',
        [parameter()]        
        [string]
        $Store = 'My',
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $IsValid = $false

    $CertificateLocation = "cert:\$Location\$Store\$Name"

    if ($Ensure -like 'Present')
    {
        Write-Verbose "Checking for $Name to be present in the $location store under $store."
        if (Test-Path $CertificateLocation)
        {
            Write-Verbose "Found a matching certficate at $CertificateLocation"
            $IsValid = $true
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateLocation"
        }
    }
    else
    {
        Write-Verbose "Checking for $Name to be absent in the $location store under $store."
        if (Test-Path $CertificateLocation)
        {
            Write-Verbose "Found a matching certficate at $CertificateLocation"            
        }
        else
        {
            Write-Verbose "Unable to find a matching certficate at $CertificateLocation"
            $IsValid = $true
        }
    }

    #Needs to return a boolean  
    return $IsValid
}


