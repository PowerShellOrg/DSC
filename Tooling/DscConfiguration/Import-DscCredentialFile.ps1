function Import-DscCredentialFile
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory)]
        [string] $Path
    )

    try
    {
        try
        {
            $savedTable = Get-Hashtable -Path $Path -ErrorAction Stop
        }
        catch
        {
            # If the file doesn't contain valid hashtable text, we assume that it's
            # a legacy file encrypted with the old code, and just return $null.  The
            # calling function will then attempt to load up the file with the legacy code.

            # Once we remove support for the old encrypted format, we can just rethrow
            # the error from Get-Hashtable here.

            return
        }

        Write-Verbose "Importing $($savedTable.Count) encrypted credentials from file $Path"

        $returnTable = @{}

        foreach ($key in $savedTable.Keys)
        {
            $bytes = [System.Convert]::FromBase64String($savedTable[$key])
            $xml = [System.Text.Encoding]::UTF8.GetString($bytes)
            $protectedData = [System.Management.Automation.PSSerializer]::Deserialize($xml)
            $credential = Unprotect-Data -InputObject $protectedData -Certificate $script:LocalCertificatePath -ErrorAction Stop

            if ($credential -isnot [pscredential])
            {
                throw "Encrypted credential with index $key was invalid.  Returned type $($credential.GetType().FullName) instead of PSCredential."
            }

            Write-Verbose "Successfully decrypted credential of user $($credential.UserName)"
            $returnTable[$credential.UserName] = $credential
        }

        Write-Verbose 'Finished importing credentials.'

        return $returnTable
    }
    catch
    {
        throw
    }
}
