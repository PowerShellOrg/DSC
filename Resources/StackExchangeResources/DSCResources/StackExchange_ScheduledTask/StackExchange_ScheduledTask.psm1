

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
        #[ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]        
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
    
    $Session = new-pssession -computername $env:computername -Credential $Credential -Authentication CredSSP
    $Job =Invoke-Command -Session $Session  { Get-ScheduledJob -Name $Name -ErrorAction SilentlyContinue }

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
        #[ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]        
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

    

    if ($Ensure -like 'Present')
    {
        
        $JobParameters = @{
            Name = $Name
            FilePath = $FilePath        
            #Credential = $credential
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
        $JobParameters.Trigger = New-JobTrigger @JobTriggerParameters
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
        #[ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]        
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

    New-TargetResourceObject @psboundparameters    
    
    if ($script:TargetResource.Ensure -like 'Present')
    {
        if ($script:TargetResource.Job)
        {
            Test-JobFilePath   
            Test-JobTriggerAtTime 
            Test-JobFrequency        
            
            if ($script:TargetResource.Once) {
                Test-OnceJobTrigger
            }
            if ($script:TargetResource.Daily) {
                Test-DailyJobTrigger
            }
            if ($script:TargetResource.Weekly) {
                Test-WeeklyJobTrigger
            }      
        }
        else
        {
            $script:TargetResource.IsValid = $false
            Write-Verbose "Unable to find matching job."
        }
    }
    else
    {
        if ($script:TargetResource.job)
        {
            $script:TargetResource.IsValid = $false
            Write-Verbose "Job should not be present, but is registered."
        }
        else
        {
            Write-Verbose "No job found and no job should be present."
        }
    }


    return $script:TargetResource.IsValid
}

$TargetResource = $null
function New-TargetResourceObject {
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
        #[ValidateSet('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')]         
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
    if (-not $psboundparameters.containskey('At')) {
        $psboundparameters.Add('At', $At)
    }
    if (-not $psboundparameters.containskey('Hours')) {
        $psboundparameters.Add('Hours', $Hours)
    }
    if (-not $psboundparameters.containskey('Minutes')) {
        $psboundparameters.Add('Minutes', $Minutes)
    }
    if (-not $psboundparameters.containskey('Once')) {
        $psboundparameters.Add('Once', $Once)
    }
    if (-not $psboundparameters.containskey('Daily')) {
        $psboundparameters.Add('Daily', $Daily)
    }
    if (-not $psboundparameters.containskey('Weekly')) {
        $psboundparameters.Add('Weekly', $Weekly)
    }

    
    $Job = Get-ScheduledJob -Name $Name -ErrorAction SilentlyContinue
    if ($Job) {
        $psboundparameters.Add('Job', $Job)    
    }
    if (-not $psboundparameters.containskey('Ensure')) {
        $psboundparameters.Add('Ensure', $Ensure)
    }
    $psboundparameters.Add('IsValid', $true)
    $script:TargetResource = [pscustomobject]$psboundparameters
}

function Remove-Job {
    param (
        [parameter()]
        [string]
        $Name,
        [parameter()]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    $Session = new-pssession -computername $env:computername -Credential $Credential -Authentication CredSSP
    
    Invoke-Command -Session $Session  {
        $Job = Get-ScheduledJob -Name $using:Name -ErrorAction SilentlyContinue
        if ($Job)
        {
            $job | Unregister-ScheduledJob -Force -Confirm:$False
        }
    }
}

function Test-JobFilePath {
    [cmdletbinding()]
    param ()

    if ($script:TargetResource.IsValid) {
        Write-Verbose "Comparing $($script:TargetResource.FilePath) to $($script:TargetResource.Job.Command)"
        $script:TargetResource.IsValid =  $script:TargetResource.FilePath -like $script:TargetResource.Job.Command 
    }    
    Write-Verbose "Checking Filepath against existing command.  Status is $($script:TargetResource.IsValid)."
}

function Test-JobTriggerAtTime {
    [cmdletbinding()]
    param ()  
      
    $Trigger = $script:TargetResource.job.JobTriggers[0]
    if ($script:TargetResource.IsValid) {
        if ($Trigger.At.HasValue) {
            $script:TargetResource.IsValid =  [datetime]::Parse($script:TargetResource.At) -eq $Trigger.At.Value 
        }
        else {
            $script:TargetResource.IsValid = $False
        }
    }
    Write-Verbose "Checking Job Trigger At time.  Status is $($script:TargetResource.IsValid)."    
}

function Test-JobFrequency {
    [cmdletbinding()]
    param()

    $Frequency = $script:TargetResource.Job.JobTriggers[0].Frequency
    if ($script:TargetResource.Once) {
        $script:TargetResource.IsValid = 'Once' -like $Frequency
    }
    if ($script:TargetResource.Daily) {
        $script:TargetResource.IsValid = 'Daily' -like $Frequency
    }
    if ($script:TargetResource.Weekly) {
        $script:TargetResource.IsValid = 'Weekly' -like $Frequency
    }
}

function Test-OnceJobTrigger {
    [cmdletbinding()]
    param ()

    $Trigger = $script:TargetResource.Job.JobTriggers[0]
    if ($script:TargetResource.IsValid -and $script:TargetResource.Once) {
        if ($Trigger.RepetitionInterval.HasValue) {
            $script:TargetResource.IsValid = $script:TargetResource.Hours -eq $Trigger.RepetitionInterval.Value.Hours 
            $script:TargetResource.IsValid = $script:TargetResource.Minutes -eq $Trigger.RepetitionInterval.Value.Minutes
        }
        else {
            $script:TargetResource.IsValid = $false
        }
    } 
    Write-Verbose "Checking Job Trigger repetition is set to Once.  Status is $($script:TargetResource.IsValid)."    
}

function Test-DailyJobTrigger {
    [cmdletbinding()]
    param ()

    $Trigger = $script:TargetResource.Job.JobTriggers[0]    
    if ($script:TargetResource.IsValid -and $script:TargetResource.Daily) {        
        $script:TargetResource.IsValid = $script:TargetResource.DaysInterval -eq $Trigger.Interval
    }
    Write-Verbose "Checking Job Trigger repetition is set to Daily.  Status is $($script:TargetResource.IsValid)."
}

function Test-WeeklyJobTrigger
{
    [cmdletbinding()]
    param()
    
    $Trigger = $script:TargetResource.Job.JobTriggers[0]
    if ($script:TargetResource.IsValid -and $script:TargetResource.Weekly) {
        Test-DaysOfWeekInWeeklyJobTrigger
    }
    Write-Verbose "Checking Job Trigger repetition is set to Weekly.  Status is $($script:TargetResource.IsValid)."    
}

function Test-DaysOfWeekInWeeklyJobTrigger {
    [cmdletbinding()]
    param()

    if ( $script:TargetResource.DaysOfWeek.Count -eq $Trigger.DaysOfWeek.count ){
        if ($script:TargetResource.DaysOfWeek.count -gt 0) {
            foreach ($day in $Trigger.DaysOfWeek) {
                if (-not $script:TargetResource.IsValid) {
                    break
                }                        
                $script:TargetResource.IsValid = ($script:TargetResource.DaysOfWeek -contains $day)
            }
        }         
    }
    else {
        $script:TargetResource.IsValid = $false
    }
}






