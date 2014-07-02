function New-Credential
{
    param ($username, $password)
    $securepassword = $password | ConvertTo-SecureString -AsPlainText -Force
    return (New-Object System.Management.Automation.PSCredential -ArgumentList $username, $securepassword)
}



