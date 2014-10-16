function Export-DscCredentialFile
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable] $Hashtable,

        [Parameter(Mandatory)]
        [string] $Path
    )

    Write-Verbose "Encrypting $($Hashtable.Count) credentials for export."

    $newTable = @{}
    try
    {
        foreach ($key in $HashTable.Keys)
        {
            Write-Verbose "Encrypting credential of user $key"

            $protectedData = Protect-Data -InputObject $HashTable[$key] -Certificate $script:LocalCertificatePath -SkipCertificateVerification -ErrorAction Stop
            $xml = [System.Management.Automation.PSSerializer]::Serialize($protectedData, 5)
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($xml)
            $base64 = [System.Convert]::ToBase64String($bytes)

            $newTable[$key] = $base64
        }
    }
    catch
    {
        throw
    }

    Write-Verbose "Encryption complete.  Saving credentials to file $Path"

    '@{' | Out-File $Path -Encoding utf8
    foreach ($key in $newTable.Keys)
    {
        "    '$key' = '$($newTable[$key])'" | Out-File $Path -Append -Encoding utf8
    }
    '}' | Out-File $Path -Append -Encoding utf8
}
