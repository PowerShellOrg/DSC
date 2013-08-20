function Get-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [string]
        $hostName,

        [parameter(Mandatory = $true)]
        [string]
        $IPAddress
    )
    
    $Configuration = @{
        HostName = $hostName
        IPAddress = $IPAddress
    }

    if ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$ipAddress\s+$hostName") {
        Write-Verbose "host entry exists in ${env:windir}\system32\drivers\etc\host"
        $Configuration.Add('Ensure','Present')
    } else {
        Write-Verbose "host entry does not exist in ${env:windir}\system32\drivers\etc\host"
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

    $hostEntry = "`n${ipAddress}`t${hostName}"

    if ($Ensure -eq 'Present')
    {
        Add-Content -Path "${env:windir}\system32\drivers\etc\hosts" -Value $hostEntry -Force -Encoding ASCII
        Write-Verbose "Hosts file entry added"
    }
    else
    {
        (Get-Content "${env:windir}\system32\drivers\etc\hosts") -notmatch "^[^#]*$ipAddress\s+$hostName" | Set-Content "${env:windir}\system32\drivers\etc\hosts"
        Write-Verbose "Hosts file entry removed"
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

    $entryExist = ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$ipAddress\s+$hostName")
    
    if ($Ensure -eq "Present") {
        if ($entryExist) {
            Write-Verbose "Host entry exists"
            return $true
        } else {
            Write-Verbose "Host entry does not exist"
            return $false
        }
    } else {
        if ($entryExist) {
            Write-Verbose "Host entry exists while it should not"
            return $false
        } else {
            Write-Verbose "Host entry does not exist"
            return $true
        }
    }
}