function New-DscZipFile
{
    param(
        ## The name of the zip archive to create
        [parameter(ValueFromPipelineByPropertyName)]
        [alias('Name')]
        [string]
        $ZipFile,

        ## The name of the folder to archive
        [parameter(ValueFromPipelineByPropertyName)]
        [alias('FullName')]
        [string]
        $Path,

        ## Switch to delete the zip archive if it already exists.
        [Switch] $Force
    )


    begin
    {
        [Byte[]] $zipHeader = 0x50,0x4B,0x05,0x06,0x00,0x00,0x00,0x00,
                                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                0x00,0x00,0x00,0x00,0x00,0x00
    }
    process
    {
        ## Create the Zip File
        $Version = Get-DscResourceVersion $path
        $folderName = $ZipFile + "_"+ $Version

        $ZipName = $executionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$folderName.zip")
        Write-Verbose "Packing $path to to $ZipName."

        ## Check if the file exists already. If it does, check
        ## for -Force - generate an error if not specified.
        if(Test-Path $zipName)
        {
            if($Force)
            {
                Write-Verbose "Removing previous $zipname"
                Remove-Item $zipName -Force
            }
            else
            {
                throw "Item with specified name $zipName already exists."
            }
        }

        try
        {
            $shellObject = New-Object -comobject "Shell.Application"

            Write-Verbose "Creating new zip file $ZipName."
            $Writer = New-Object System.IO.FileStream $ZipName, "Create"
            $Writer.Write($zipheader, 0, 22)
            $Writer.Close();

            Start-Sleep -Seconds 1
            $ZipFileObject = $shellObject.namespace($ZipName)

            Write-Verbose "Loading the zip file contents."
            $ZipFileObject.CopyHere($Path)
            Start-Sleep -Seconds 5
        }
        finally
        {
            ## Release the shell object
            $shellObject = $null
            $ZipFileObject = $null
        }
        get-item $ZipName
    }
}



