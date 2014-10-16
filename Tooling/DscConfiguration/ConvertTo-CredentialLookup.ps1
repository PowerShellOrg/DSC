function ConvertTo-CredentialLookup
{
    param (
        [parameter(
            ValueFromPipeline,
            Mandatory
        )]
        [System.Collections.Hashtable]
        $PasswordHashtable
    )
    begin
    {
        $CredentialHashtable = @{}
    }
    Process
    {
        foreach ($key in $PasswordHashtable.Keys)
        {
            Write-Verbose "Creating new credential for $key"
            $CredentialHashtable.Add($key, (New-Credential -username $key -password $PasswordHashtable[$key]))
        }
    }
    end
    {
        $CredentialHashtable
    }
}




