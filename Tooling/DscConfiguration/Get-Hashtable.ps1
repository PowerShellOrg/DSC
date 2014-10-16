function Get-Hashtable
{
    # Path to PSD1 file to evaluate
    param (
        [parameter(
            Position = 0,
            ValueFromPipelineByPropertyName,
            Mandatory
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string]
        $Path
    )
    process
    {
        # This code is duplicated in the DscBuild module's Import-DataFile function.
        # I don't really want to create any coupling between those two modules, but maybe
        # we can extract some common code into a utility module that's leveraged by both,
        # at some point.

        Write-Verbose "Loading data from $Path."

        try
        {
            $content = Get-Content -Path $Path -Raw -ErrorAction Stop
            $scriptBlock = [scriptblock]::Create($content)

            [string[]] $allowedCommands = @(
                'Import-LocalizedData', 'ConvertFrom-StringData', 'Write-Host', 'Out-Host', 'Join-Path'
            )

            [string[]] $allowedVariables = @('PSScriptRoot')

            $scriptBlock.CheckRestrictedLanguage($allowedCommands, $allowedVariables, $true)

            return & $scriptBlock
        }
        catch
        {
            throw
        }
    }
}




