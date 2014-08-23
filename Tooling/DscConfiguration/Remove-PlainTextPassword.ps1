function Remove-PlainTextPassword
{
    param (
        [parameter()]
        [string]
        $path
    )

    Start-Sleep -seconds 2
    Write-Verbose "Removing plain text credentials from $path"
    Remove-Item $path -Confirm:$false -Force
}




