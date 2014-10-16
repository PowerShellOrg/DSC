function New-Credential
{
    param ($username, $password)

    if ($password -isnot [securestring])
    {
        $password = $password | ConvertTo-SecureString -AsPlainText -Force
    }

    return New-Object System.Management.Automation.PSCredential -ArgumentList $username, $password
}
