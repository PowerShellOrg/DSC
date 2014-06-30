# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'    
    CheckingHostsFileEntry=Checking if the hosts file entry exists.
    HostsFileEntryFound=Found a hosts file entry for {0} and {1}.
    HostsFileEntryNotFound=Did not find a hosts file entry for {0} and {1}.
    HostsFileShouldNotExist=Hosts file entry exists while it should not.
    HostsFileEntryShouldExist=Hosts file entry does not exist while it should.
    CreatingHostsFileEntry=Creating a hosts file entry with {0} and {1}.
    RemovingHostsFileEntry=Removing a hosts file entry with {0} and {1}.
    HostsFileEntryAdded=Created the hosts file entry for {0} and {1}.
    HostsFileEntryRemoved=Removed the hosts file entry for {0} and {1}.
    AnErrorOccurred=An error occurred while creating hosts file entry: {1}.
    InnerException=Nested error trying to create hosts file entry: {1}.
'@
}
if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename HostsFileProvider.psd1
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $hostName,
        [parameter(Mandatory = $true)]
        [string]
        $ipAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    $Configuration = @{
        HostName = $hostName
        IPAddress = $IPAddress
    }

    Write-Verbose $localizedData.CheckingHostsFileEntry
    try {
        if ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$ipAddress\s+$hostName") {
            Write-Verbose ($localizedData.HostsFileEntryFound -f $hostName, $ipAddress)
            $Configuration.Add('Ensure','Present')
        } else {
            Write-Verbose ($localizedData.HostsFileEntryNotFound -f $hostName, $ipAddress)
            $Configuration.Add('Ensure','Absent')
        }
        return $Configuration
    }

    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
        }        
    }
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [string]
        $hostName,
        [parameter(Mandatory = $true)]
        [string]
        $ipAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )     

    $hostEntry = "`r`n${ipAddress}`t${hostName}"

    try {

        if ($Ensure -eq 'Present')
        {
            Write-Verbose ($localizedData.CreatingHostsFileEntry -f $hostName, $ipAddress)
            Add-Content -Path "${env:windir}\system32\drivers\etc\hosts" -Value $hostEntry -Force -Encoding ASCII
            Write-Verbose ($localizedData.HostsFileEntryAdded -f $hostName, $ipAddress)
        }
        else
        {
            Write-Verbose ($localizedData.RemovingHostsFileEntry -f $hostName, $ipAddress)
            ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -notmatch "^\s*$") -notmatch "^[^#]*$ipAddress\s+$hostName" | Set-Content "${env:windir}\system32\drivers\etc\hosts"
            Write-Verbose ($localizedData.HostsFileEntryRemoved -f $hostName, $ipAddress)
        }
    }
    catch {
            $exception = $_    
            Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
            while ($exception.InnerException -ne $null)
            {
                $exception = $exception.InnerException
                Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
            }
    }

}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [string]
        $hostName,
        [parameter(Mandatory = $true)]
        [string]
        $ipAddress,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )  

    try {
        Write-Verbose $localizedData.CheckingHostsFileEntry
        $entryExist = ((Get-Content "${env:windir}\system32\drivers\etc\hosts") -match "^[^#]*$ipAddress\s+$hostName")

        if ($Ensure -eq "Present") {
            if ($entryExist) {
                Write-Verbose ($localizedData.HostsFileEntryFound -f $hostName, $ipAddress)
                return $true
            } else {
                Write-Verbose ($localizedData.HostsFileEntryShouldExist -f $hostName, $ipAddress)
                return $false
            }
        } else {
            if ($entryExist) {
                Write-Verbose $localizedData.HostsFileShouldNotExist
                return $false
            } else {
                Write-Verbose $localizedData.HostsFileEntryNotFound
                return $true
            }
        }
    }
    catch {
        $exception = $_    
        Write-Verbose ($LocalizedData.AnErrorOccurred -f $name, $exception.message)
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose ($LocalizedData.InnerException -f $name, $exception.message)
        }
    }
}


