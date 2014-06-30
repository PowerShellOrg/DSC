
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name
    )
    
    #Needs to return a hashtable that returns the current
    #status of the configuration component
    
    $Configuration = @{
        Name = (tzutil /g)
        Ensure = 'Present'        
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
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    if ($ensure -like 'Present')
    {
        tzutil /s "$Name"
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
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $CurrentTimeZone = tzutil.exe /g
    
    if ($Ensure -like 'present')
    {
        if ($Name -like $CurrentTimeZone)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
    else
    {
        if ($Name -like $CurrentTimeZone)
        {
            return $false
        }
        else
        {
            return $true
        }
    }
    
}


