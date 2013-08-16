
# Fallback message strings in en-US
DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @'    
AutomaticPageFileConfigured=The page file is set to automatic configuration.
'@
}

Import-LocalizedData LocalizedData -filename PagefileProvider.psd1

function Get-TargetResource
{
    param (
	[parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
#CODE
}

function Set-TargetResource
{
    param (
	[parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
#CODE
}

function Test-TargetResource
{
    param (
	[parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
#CODE
}
