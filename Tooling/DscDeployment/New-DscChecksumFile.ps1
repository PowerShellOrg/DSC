function New-DscChecksumFile
{
    param (
        [parameter(ValueFromPipeline)]
        [IO.FileSystemInfo]
        $InputObject
    )
    process
    {
        $checksumfile = "$($inputobject.fullname).checksum"              
        $hash = (Get-FileHash -path $inputobject.fullname).hash 
        Write-Verbose "Hash for $($InputObject.fullname) is $hash."
        if (test-path $checksumfile)
        {
            Write-verbose "Removing previous checksum file $checksumfile"
            remove-item $checksumfile -Force
        }
        [io.file]::AppendallText($checksumfile, $hash)
        Write-Verbose "Hash written to file is $(Get-Content $checksumfile -Raw)."
        Write-Verbose "Wrote hash for $($InputObject.FullName) to $checksumfile"
    }            
}