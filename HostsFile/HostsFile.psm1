function Get-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [string]
        $hostname,

        [parameter(Mandatory = $true)]
        [string]
        $IPAddress,

        [parameter()]
        [string]
        [ValidateSet('Present','Absent')]
        $Ensure='Present'
    )
    
    $Configuration = @{
        HostName = $hostname
        IPAddress = $IPAddress
    }
    
    $hostEntry = "${ipAddress}`t${hostName}"
    Write-Verbose $hostEntry

    if ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -contains $hostEntry) {
        Write-Verbose "${hostEntry} exists in ${env:windir}\system32\drivers\etc\host"
        $Configuration.Add('Ensure','Present')
    } else {
        Write-Verbose "${hostEntry} does not exist in ${env:windir}\system32\drivers\etc\host"
        $Configuration.Add('Ensure','Absent')
    }
    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        $hostName,
        [parameter(Mandatory = $true)]
        $ipAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        $Ensure = 'Present'
    )     

    $hostEntry = "${ipAddress}`t${hostName}"

    if ($Ensure -eq 'Present')
    {
        Add-Content -Path "${env:windir}\system32\drivers\etc\hosts" -Value $hostEntry -Force -Encoding ASCII
        Write-Verbose "${hostEntry} added"
    }
    else
    {
        (Get-Content "${env:windir}\system32\drivers\etc\hosts") -notmatch "\b$hostEntry\b" | Set-Content "${env:windir}\system32\drivers\etc\hosts"
        Write-Verbose "${hostEntry} removed"
    }

}

function Test-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        $hostName,
        [parameter(Mandatory = $true)]
        $ipAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    $Valid = $true
    $hostEntry = "${ipAddress}`t${hostName}"
    Write-Verbose $hostEntry

    $entryExist = ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -contains $hostEntry)
    
    if ($Ensure -eq "Present") {
        if ($entryExist) {
            Write-Verbose "${hostEntry} exists"
            $valid = $true
        } else {
            Write-Verbose "${hostEntry} does not exist"
            $valid = $false
        }
    } else {
        if ($entryExist) {
            Write-Verbose "${hostEntry} exists while it should not"
            $valid = $false
        } else {
            Write-Verbose "${hostEntry} does not exist"
            $valid = $true
        }
    }

    return $valid
}