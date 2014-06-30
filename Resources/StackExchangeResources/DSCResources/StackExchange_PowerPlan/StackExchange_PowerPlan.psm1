$CIMParameters = @{
    Namespace = 'root\cimv2\power'
    Class = 'Win32_PowerPlan'
}

DATA localizedData
{
    # same as culture = "en-US"
    ConvertFrom-StringData @'    
ElementName=Adding filter for Element Name of {0}
FilterText=Adding the filter text ({0}) to the query.
IsActiveFilter=Adding filter for IsActive = True
NoFilterCriteria=No filter criteria.  Making sure nothing is hanging around.
Cruft=Found some cruft.  Removing.
MatchingActivePowerPlan=Found a matching active powerplan.
NoMatchingActivePowerPlan=Did not a matching active powerplan.
SettingActivePowerPlan=Setting active Power Plan to {0}
CurrentPowerPlan=Current Power Plan is set to {0}.
CheckingForActivePowerPlan=Checking for an active powerplan called {0}.
ActivePlanNotSetTo=The active Power Plan is not set to {0}.
ActivePlanSetTo=The active Power Plan is set to {0}.  All good here.
ActivePlanSetToAndShouldNotBe=The active Power Plan is set to {0}, and should not be.
ActivePlanNotSetToAndShouldNotBe=The active Power Plan is not set to {0}, and should not be.  All good here.
'@
}

if (Test-Path $PSScriptRoot\en-us)
{
    Import-LocalizedData LocalizedData -filename PowerPlanProvider.psd1
}


function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]        
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $powerplan = Get-CIMPowerPlan -name $Name -active
    
    $Configuration = @{
        Name = $Name
    }

    If ($PowerPlan)
    {
        #Needs to return a hashtable that returns the current
        #status of the configuration component
        Write-Verbose $LocalizedData.MatchingActivePowerPlan
        $Configuration.Ensure = 'Present'
    }
    else
    {
        Write-Verbose $LocalizedData.NoMatchingActivePowerPlan
        $Configuration.Ensure = 'Absent'
    }
    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]        
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    if ($Ensure -like 'Present')
    {        
        Set-CIMPowerPlan -name $Name
    }
    else
    {        
        Write-Verbose ($localizedData.CurrentPowerPlan -f $Name)
        switch ($Name)
        {
            'Balanced' { Set-CimPowerPlan -name 'High Performance' }            
            default { Set-CimPowerPlan -name 'Balanced' }
        }
    }

}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]        
        [string]
        $Name,
        [parameter()]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )
    
    $Valid = $true

    Write-Verbose ($LocalizedData.CheckingForActivePowerPlan -f $Name)
    $PowerPlan = Get-CIMPowerPlan -active -name $Name

    if ($Ensure -like 'Present')
    {
         if ( $PowerPlan -eq $null ) 
         {
            Write-Verbose ($LocalizedData.ActivePlanNotSetTo -f $Name)
            $Valid = $false    
         }       
         else
         {
            Write-Verbose ($LocalizedData.ActivePlanSetTo -f $Name)
         }  
    }
    else
    {
        if ( $PowerPlan -ne $null )
        {
            Write-Verbose ($LocalizedData.ActivePlanSetToAndShouldNotBe -f $Name)
            $Valid = $false
        }
        else
        {
            Write-Verbose ($LocalizedData.ActivePlanNotSetToAndShouldNotBe -f $Name)
        }
    }
    return $valid
}

Function Get-CIMPowerPlan
{
    param ([string]$name, [switch]$active)

    $FilterText = ''
    if (-not [string]::IsNullOrEmpty($name))
    {   
        if (-not [string]::IsNullOrEmpty($FilterText))
        {
            $FilterText += ' and ' 
        }
        Write-Debug ($LocalizedData.ElementName -f $Name)
        $FilterText += "ElementName like '$Name'" 
    }
    if ($active)
    {        
        if (-not [string]::IsNullOrEmpty($FilterText))
        {
            $FilterText += ' and ' 
        }
        Write-Debug $LocalizedData.IsActiveFilter
        $FilterText += "IsActive = 'True'"
    }

    if ([string]::IsNullOrEmpty($FilterText))
    {
        Write-Debug $LocalizedData.NoFilterCriteria
        if ($CIMParameters.ContainsKey('Filter'))
        {
            Write-Debug $LocalizedData.Cruft
            $CIMParameters.Remove('Filter') | Out-Null
        }
    }
    else
    {
        Write-Debug  ($LocalizedData.FilterText -f $FilterText)
        $CIMParameters.Filter = $FilterText
    }

    Get-CimInstance @CIMParameters
        
}

function Set-CIMPowerPlan
{
    param ($name)    

    Write-Verbose ($LocalizedData.SettingActivePowerPlan -f $Name)

    Get-CIMPowerPlan -name $name | 
            Invoke-CimMethod -MethodName Activate
}


