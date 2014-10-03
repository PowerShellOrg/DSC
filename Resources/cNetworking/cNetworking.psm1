function Convert-MacAddress
{
    <#
    .SYNOPSIS
        Converts a MAC address from any valid format to another.

    .DESCRIPTION
        The Convert-MacAddress function takes any valid MAC address and converts it to another valid format.
        Valid formats are:
        - Six groups of two hex digits separated by hyphens (-), like 01-23-45-ab-cd-ef
        - Six groups of two hex digits separated by colons (:), like 01:23:45:ab:cd:ef
        - Three groups of four hex digits separated by dots (.), like 0123.45ab.cdef
        - No groups (raw), like 012345abcdef
    
    .PARAMETER MacAddress
        Specify a valid MAC address to be converted.

    .PARAMETER Format
        Specify the format (Colon, Hyphen, Dot, Raw).
        Default: Colon

    .EXAMPLE
        Convert-MacAddress -MacAddress 012345abcdef

        01:23:45:ab:cd:ef

    .EXAMPLE
        Convert hyphen formatted MAC address to Colon format:

        Convert-MacAddress -MacAddress 01-23-45-ab-cd-ef -Format Colon

        01:23:45:ab:cd:ef

    .EXAMPLE
        Convert raw (no delimiters) MAC address to Colon format:

        Convert-MacAddress -MacAddress 012345abcdef -Format Colon

        01:23:45:ab:cd:ef

    .EXAMPLE
        Convert raw (no delimiters) MAC address to Colon format:

        Convert-MacAddress -MacAddress 012345abcdef -Format Hyphen

        01-23-45-ab-cd-ef

    .EXAMPLE
        Convert hyphen formatted MAC address to Dot format:

        Convert-MacAddress -MacAddress 01-23-45-ab-cd-ef -Format Dot

        0123.45ab.cdef

    .EXAMPLE
        Convert hyphen formatted MAC address to Raw format:

        Convert-MacAddress -MacAddress 01-23-45-ab-cd-ef -Format Raw

        012345abcdef

    .NOTES
        Author: Daniel Krebs
        Created: 2014-10-03
        Version: 1.0.0.0

    .LINK
        http://en.wikipedia.org/wiki/MAC_address
    .
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$MacAddress,

        [ValidateSet('Colon','Hyphen','Dot', 'Raw')]
        [System.String]$Format = 'Colon'
    )
    begin
    {
        $FormatTable = @{'Colon' = ':'; 'Hyphen' = '-'; 'Dot' = '.'}

        # Convert to raw format (no delimiters)
        $MacAddressConverted = $MacAddress -replace '(:|-|\.)'
    }

    process
    {
        # Valid MAC address characters
        if ($MacAddressConverted -match '[0-9a-f]{12}')
        {
            # Skip processing if Raw format
            if ($Format -ne 'Raw')
            {
                # Get delimiter from format table
                $Delimiter = $FormatTable[$Format]

                # Determine group length based on delimiter
                $GroupLength = if ($Delimiter -eq '.') { 4 } else { 2 }

                # Create array list, iterate of MAC address string and add hex digit groups
                $MacAddressArray = New-Object -TypeName System.Collections.ArrayList
                for ($Index = 0; $Index -lt $MacAddressConverted.Length; $Index += $GroupLength)
                {
                    [void]$MacAddressArray.Add($MacAddressConverted.Substring($Index, $GroupLength))
                }

                # Join hex digit groups in array list with the delimiter of the selected format
                $MacAddressConverted = $MacAddressArray -join $Delimiter
            }
        }
        else
        {
            throw 'Invalid MAC address format.'
        }
    }

    end
    {
        # Return the converted MAC address
        Write-Output -InputObject $MacAddressConverted
    }
}