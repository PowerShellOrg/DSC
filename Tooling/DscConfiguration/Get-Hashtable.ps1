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
        Write-Verbose "Loading data from $Path."
        invoke-expression "DATA { $(get-content -raw -path $path) }"
    }    
}



