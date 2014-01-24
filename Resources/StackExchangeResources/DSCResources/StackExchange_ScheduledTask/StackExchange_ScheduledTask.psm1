

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath,

        [parameter()]
        [string]
        $At = (Get-Date),

        [parameter()]
        [int]
        $Hours = 0,

        [parameter()]
        [int]
        $Minutes = 0,
        
        [parameter()]        
        [bool]
        $Once = $false,

        [parameter()]
        [int]
        $DaysInterval,
        
        [parameter()]        
        [bool]
        $Daily = $false,
        
        [parameter()]        
        [string[]]
        $DaysOfWeek,

        [parameter()]        
        [bool]
        $Weekly = $false,

        [parameter()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $Job = Get-ScheduledJob -Name $Name -ErrorAction SilentlyContinue

    #Needs to return a hashtable that returns the current
    #status of the configuration component

    $Configuration = @{
        Name = $Name    
    }
    if ($Job)
    {
        $Configuration.FilePath = $Job.Command
        if ($Job.JobTriggers[0].At.HasValue)
        {
            $Configuration.At = $job.JobTriggers[0].At.Value.ToString()
        }
        if ($Job.JobTriggers[0].RepetitionInterval.HasValue)
        {           
            $Configuration.Hours = $Job.JobTriggers[0].RepetitionInterval.Value.Hours
            $Configuration.Minutes = $Job.JobTriggers[0].RepetitionInterval.Value.Minutes
        }
        
        if ( 'Once' -like $Job.JobTriggers[0].Frequency )
        {
            $Configuration.Once = $true
        }
        else
        {
            $Configuration.Once = $false
        }
        if ( 'Daily' -like $Job.JobTriggers[0].Frequency )
        {
            $Configuration.Daily = $true
            $Configuration.DaysInterval = $Job.JobTriggers[0].Interval
        }
        else
        {
            $Configuration.Daily = $false            
        }
        if ( 'Weekly' -like $Job.JobTriggers[0].Frequency )
        {
            $Configuration.Weekly = $true
            [string[]]$Configuration.DaysOfWeek = $job.JobTriggers[0].DaysOfWeek
        }
        else
        {
            $Configuration.Weekly = $false            
        }
        $Configuration.Ensure = 'Present'
    }
    else
    {
        $Configuration.FilePath = $FilePath
        $Configuration.Ensure = 'Absent'
    }

    return $Configuration
}

function Set-TargetResource
{
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath,

        [parameter()]
        [string]
        $At = (Get-Date),

        [parameter()]
        [int]
        $Hours = 0,

        [parameter()]
        [int]
        $Minutes = 0,
        
        [parameter()]        
        [bool]
        $Once = $false,

        [parameter()]
        [int]
        $DaysInterval = 0,
        
        [parameter()]        
        [bool]
        $Daily = $false,
        
        [parameter()]        
        [string[]]
        $DaysOfWeek,

        [parameter()]        
        [bool]
        $Weekly = $false,

        [parameter()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $Job = Get-ScheduledJob -Name $Name -ErrorAction SilentlyContinue
    if ($Job)
    {
        $job | Unregister-ScheduledJob -Force
    }

    if ($Ensure -like 'Present')
    {
        
        $JobParameters = @{
            Name = $Name
            FilePath = $FilePath        
            Credential = $credential
            MaxResultCount = 10
        }
        $JobTriggerParameters = @{}
        $JobTriggerParameters.At = $At 
        if ($Once)
        {
            $JobTriggerParameters.Once = $true          
            if (($Hours -gt 0) -or ($Minutes -gt 0))
            {
                $JobTriggerParameters.RepetitionInterval = New-TimeSpan -Hours $Hours -Minutes $Minutes
                $JobTriggerParameters.RepetitionDuration = [timespan]::MaxValue
            }
        }
        elseif ($Daily)
        {
            $JobTriggerParameters.Daily = $true    
            if ($DaysInterval -gt 0)
            {
                $JobTriggerParameters.DaysInterval = $DaysInterval
            }
        }
        elseif ($Weekly)
        {
            $JobTriggerParameters.Weekly = $true
            if ($DaysOfWeek.count -gt 0)
            {
                $JobTriggerParameters.DaysOfWeek = $DaysOfWeek
            }
        }
        $JobParameters.Trigger = New-JobTrigger
        Register-ScheduledJob @JobParameters
    }
    else
    {
        Write-Verbose "Job $Name removed."
    }

}

function Test-TargetResource
{
    [OutputType([boolean])]
    param (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $FilePath,

        [parameter()]
        [string]
        $At = (Get-Date),

        [parameter()]
        [int]
        $Hours = 0,

        [parameter()]
        [int]
        $Minutes = 0,
        
        [parameter()]        
        [bool]
        $Once = $false,

        [parameter()]
        [int]
        $DaysInterval,
        
        [parameter()]        
        [bool]
        $Daily = $false,
        
        [parameter()]        
        [string[]]
        $DaysOfWeek,

        [parameter()]        
        [bool]
        $Weekly = $false,

        [parameter()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    $IsValid = $true
    
    $Job = Get-ScheduledJob -Name $Name -ErrorAction SilentlyContinue
    if ($Ensure -like 'Present')
    {
        if ($Job)
        {
            $IsValid = $IsValid -and ( $FilePath -like $Job.Command )
            Write-Verbose "Checking Filepath against existing command.  Status is $IsValid."

            $IsValid = $IsValid -and (Test-JobTriggerAtTime -Trigger $job.JobTriggers[0] -At $At)
            Write-Verbose "Checking Job Trigger At time.  Status is $IsValid."
            
            $IsValid = $IsValid -and (Test-OnceJobTrigger -Trigger $job.JobTriggers[0] -Hours $Hours -Minutes $Minutes -Once $Once)
            Write-Verbose "Checking Job Trigger repetition is set to Once.  Status is $IsValid."

            $IsValid = $IsValid -and (Test-DailyJobTrigger -Trigger $Job.JobTriggers[0] -Interval $DaysInterval -Daily $Daily)            
            Write-Verbose "Checking Job Trigger repetition is set to Daily.  Status is $IsValid."
            
            $IsValid = $IsValid -and (Test-WeeklyJobTrigger -Trigger $Job.JobTriggers[0] -DaysOfWeek $DaysOfWeek -Weekly $Weekly)            
            Write-Verbose "Checking Job Trigger repetition is set to Weekly.  Status is $IsValid."            
        }
        else
        {
            $IsValid = $false
            Write-Verbose "Unable to find matching job."
        }
    }
    else
    {
        if ($job)
        {
            $IsValid = $false
            Write-Verbose "Job should not be present, but is registered."
        }
        else
        {
            Write-Verbose "No job found and no job should be present."
        }
    }


    return $IsValid
}

function Test-JobTriggerAtTime
{
    param (
        [object]
        $Trigger,
        [string]
        $At
    )  
      
    $IsValid = $Trigger.At.HasValue
    if ($IsValid)
    {
        $IsValid = $IsValid -and ( [datetime]::Parse($At) -eq $Trigger.At.Value )                
    }
    return $IsValid
}

function Test-WeeklyJobTrigger
{
    param 
    (
        [object]
        $Trigger,
        [string[]]
        $DaysOfWeek,
        [bool]
        $Weekly 
    )

    $IsValid = $true
    if ( $Weekly )    
    {
        $IsValid = $IsValid -and ( 'Weekly' -like $Trigger.Frequency )
        $IsValid = $IsValid -and ( $DaysOfWeek.Count -eq $Trigger.DaysOfWeek.count )
        if ($IsValid -and ($DaysOfWeek.count -gt 0))
        {
            foreach ($day in $Trigger.DaysOfWeek)
            {
                $IsValid = $IsValid -and ($DaysOfWeek -contains $day)
            }
        }                
    }
    else
    {
        $IsValid = $IsValid -and ( 'Weekly' -notlike $Trigger.Frequency )
    }
    return $IsValid
}

function Test-DailyJobTrigger
{
    param (
        [object]
        $Trigger,
        [int]
        $DaysInterval,
        [bool]
        $Daily
    )

    $IsValid = $true
    if ( $Daily )
    {
        $IsValid = $IsValid -and ( 'Daily' -like $Trigger.Frequency )
        $IsValid = $IsValid -and ( $DaysInterval -eq $Trigger.Interval )
    }
    else
    {
        $IsValid = $IsValid -and ( 'Daily' -notlike $Trigger.Frequency )
    }
    return $IsValid
}

function Test-OnceJobTrigger
{
    param (
        [object]
        $Trigger,
        [int]
        $Hours,
        [int]
        $Minutes,
        [bool]
        $Once
    )

    $IsValid = $true
    if ($Once)
    {
        $IsValid = $IsValid -and ( 'Once' -like $Trigger.Frequency )
        $IsValid = $IsValid -and $Trigger.RepetitionInterval.HasValue
        
        if ($IsValid)
        {           
            $IsValid = $IsValid -and ( $Hours -eq $Trigger.RepetitionInterval.Value.Hours )
            $IsValid = $IsValid -and ( $Minutes -eq $Trigger.RepetitionInterval.Value.Minutes )            
        }        
        Write-Verbose "Checking Job Trigger repetition interval.  Status is $IsValid."
    }
    else
    {
        $IsValid = $IsValid -and ( 'Once' -notlike $Trigger.Frequency )
    }
    return $IsValid
}
