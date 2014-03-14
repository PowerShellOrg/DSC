<#
 #  This script enables a user to diagnose errors caused by a DSC operation. In short, the following commands would help you diagnose errors
 #  To get the last 10 operations in DSC that show their Result status (failure,success)         : Get-cDscOperation
 #  To get a list of last n (say, 13) DSC operations                                             : Get-cDscOperation -Newest 13
 #  To see details of the last operation                                                         : Trace-cDscOperation
 #  TO view trace details of the third last operation run                                        : Trace-cDscOperation 3
 #  To view trace details of an operation with Job ID $jID                                       : Trace-cDscOperation -JobID $jID
 #  To View trace details of multiple computers                                                  : Trace-cDscOperation -ComputerName @("PN25113D0891","PN25113D0890") 
 #
 #>

#region Global variables

 $Script:DscVerboseEventIdsAndPropertyIndex=@{4100=3;4117=2;4098=3};
 $Script:DscLogName="Microsoft-windows-dsc"
 $Script:RedirectOutput=$false
 $Script:TemporaryHtmLocation="$env:TEMP/dscreport"
 $Script:SuccessResult="Success"
 $Script:FailureResult="Failure"
 $Script:ThisCredential=""
 $Script:ThisComputerName=$env:COMPUTERNAME
 $Script:UsingComputerName=$false
 $Script:FormattingFile="cDscDiagnosticsFormat.ps1xml"
 $Script:RunFirstTime = $true
#endregion

#region Cache for events
 $Script:LatestGroupedEvents=@{} #Hashtable of "Computername", "GroupedEvents"
 $Script:MostRecentJobId=@{}     #Hashtale of "ComputerName", "GroupedEvents"

#endregion

#region Exported Functions

 <#
.SYNOPSIS 
Traces through any DSC operation selected from among all operations using its unique sequence ID (obtained from Get-cDscOperation), or from its unique Job ID

.DESCRIPTION
This function, when called, will look through all the event logs for DSC, and output the results in the form of an object, that contains the event type, event message, time created, computer name, job id, sequence number, and the event information. 


.PARAMETER SequenceId
Each operation in DSC has a certain Sequence ID, ordered by time of creation of these DSC operations. The sequence IDs can be obtained by running Get-cDscOperation
By mentioning a sequence ID, the trace of the corresponding DSC operation is output.

.PARAMETER JobId
The event viewer shows each DSC event start with a unique job ID for each operation. If this job id is specified with this parameter, then all diagnostic messages displayed are taken from the dsc operation pertaining to this job id.


.PARAMETER ComputerName
The names of computers in which you would like to trace the past DSC operations


.PARAMETER Credential
The credential needed to access the computers specified inside ComputerName parameters

.EXAMPLE
To Obtain the diagnostic information for the latest operation                : 
Trace-cDscOperation 
.EXAMPLE
To obtain the diagnostic information for the third latest operation          : 
Trace-cDscOperation -sequenceId 3
.EXAMPLE
To diagnose an operation with job Id 11112222-1111-1122-1122-111122221111    : 
Trace-cDscOperation -JobId 11112222-1111-1122-1122-111122221111
.EXAMPLE
To Get Logs from a remote computer                                           : 
Trace-cDscOperation -ComputerName XYZ -sequenceID 2

To Get logs from a remote computer with credentials                          : 
Trace-cDscOperation -Computername XYZ -Credential $mycredential -sequenceID 2

To get logs from multiple remote computers                                   : 
Trace-cDscOperation -ComputerName @("PN25113D0891","PN25113D0890")
Please note that to perform actions on the remote computer, have the firewall for remote configuration enabled. This can be done with the following command:
C:> netsh firewall set service remoteadmin enable

#>
function Trace-cDscOperation
{
    
    [cmdletBinding()]
    param(
        [UInt32]$SequenceID=1, #latest is by default
        [Guid]$JobId,
        [String[]]$ComputerName,
        [pscredential]$Credential)
    Add-ClassTypes
    if($ComputerName)
    {
        $Script:UsingComputerName=$true  
        $args=$PSBoundParameters
        $null=$args.Remove("ComputerName")
        $null=$args.Remove("Credential")
            
       foreach($thisComputerName in $ComputerName)
       {
            Log -Verbose "Gathering logs for Computer $thisComputerName ..."
            $Script:ThisComputerName=$thisComputerName
            $Script:ThisCredential=$Credential
            Trace-DscOperationInternal  @PSBoundParameters
            
       }
    }
    else
    {
        $Script:ThisComputerName=$env:COMPUTERNAME
        Trace-DscOperationInternal @PSBoundParameters
         $Script:UsingComputerName=$false  
    }
}
 
  <#
.SYNOPSIS 
Gives a list of all DSC operations that were executed . Each DSC operation has sequence Id information , and job id information
It returns a list of objects, each of which contain information on a distinct DSC operation . Here a DSC operation is referred to any single DSC execution, such as start-dscconfiguration, test-dscconfiguration etc. These will log events with a unique jobID (guid) identifying the DSC operation. 

When you run Get-cDscOperation, you will see a list of past DSC operations , and you could use the following details from the output to trace any of them individually.
- Job ID : By using this GUID, you can search for the events in Event viewer, or run Trace-cDscOperation -jobID <required Jobid> to obtain all event details of that operation
- Sequence Id : By using this identifier, you could run Trace-cDscOperation <sequenceId> to get all event details of that particular dsc operation.


.DESCRIPTION
This will list all the DSC operations that were run in the past in the computer. By Default, it will list last 10 operations. 

.PARAMETER Newest
By default 10 last DSC operations are pulled out from the event logs. To have more, you could use enter another number with this parameter.a PS Object with all the information output to the screen can be navigated by the user as required.


.EXAMPLE
PS C:\> Get-cDscOperation 20 #Lists last 20 operations
PS C:\> Get-cDscOperation -ComputerName @("XYZ","ABC") -Credential $cred #Lists operations for the array of computernames passed in.
#>

function Get-cDscOperation
{
    [cmdletBinding()]
    param(
        [UInt32]$Newest=10, 
        [String[]]$ComputerName,
        [pscredential]$Credential)
    Add-ClassTypes
    if($ComputerName)
    {
        $Script:UsingComputerName=$true  
        $args=$PSBoundParameters
        $null=$args.Remove("ComputerName")
        $null=$args.Remove("Credential")
            
       foreach($thisComputerName in $ComputerName)
       {
            Log -Verbose "Gathering logs for Computer $thisComputerName"
            $Script:ThisComputerName=$thisComputerName
            $Script:ThisCredential=$Credential
            Get-DscOperationInternal  @PSBoundParameters
            
       }
    }
    else
    {
        $Script:ThisComputerName=$env:COMPUTERNAME
        Get-DscOperationInternal @PSBoundParameters
         $Script:UsingComputerName=$false  
    }

}
#endregion

#region FunctionTools

function Log
{
    param($text,[Switch]$Error,[Switch]$Verbose)
    if($Error)
    {
        Write-Error  $text 
    }
    elseif($Verbose)
    {
        Write-Verbose $text
    }

}
function Add-ClassTypes
{
    #We don't want to add the same types again and again.
    if($Script:RunFirstTime)
    {
        $pathToFormattingFile=(join-path  $PSScriptRoot $Script:FormattingFile)
        $ClassdefinitionGroupedEvents=@"
            using System;
            using System.Globalization;
            using System.Collections;
            namespace Microsoft.PowerShell.cDscDiagnostics
            {
                public class GroupedEvents {
                        public int SequenceId;
                        public System.DateTime TimeCreated;
                        public string ComputerName;
                        public string Result;
                        public Guid? JobID=null;
                        public System.Array AllEvents;
                        public int NumberOfEvents;
                        public System.Array AnalyticEvents;
                        public System.Array DebugEvents;
                        public System.Array NonVerboseEvents;
                        public System.Array VerboseEvents;
                        public System.Array OperationalEvents;
                        public System.Array ErrorEvents;
                        public System.Array WarningEvents;

                   }
            }
"@
        $ClassdefinitionTraceOutput=@"
               using System;
               using System.Globalization;
               namespace Microsoft.PowerShell.cDscDiagnostics
               {
                   public enum EventType {
                        DEBUG,
                        ANALYTIC,
                        OPERATIONAL,
                        ERROR,
                        VERBOSE
                   }
                   public class TraceOutput {
                        public EventType EventType;
                        public System.DateTime TimeCreated;
                        public string Message;
                        public string ComputerName;
                        public Guid? JobID=null;
                        public int SequenceID;
                        public System.Diagnostics.Eventing.Reader.EventRecord Event;
                   }
               }
              
"@
        Add-Type -Language CSharp -TypeDefinition $ClassdefinitionGroupedEvents
        Add-Type -Language CSharp -TypeDefinition $ClassdefinitionTraceOutput
        #Update-TypeData -TypeName TraceOutput -DefaultDisplayPropertySet EventType, TimeCreated, Message 
        Update-FormatData  -PrependPath $pathToFormattingFile 
        
        $Script:RunFirstTime = $false; #So it doesnt do it the second time.
    }
}

function Get-AllGroupedDscEvents
{
    $groupedEvents=$null
    $latestJobId=Get-DscLatestJobId
    Log -Verbose "Collecting all events from the DSC logs"
        
    if(($Script:MostRecentJobId[$Script:ThisComputerName] -eq $latestJobId )  -and $Script:LatestGroupedEvents[$Script:ThisComputerName])
    {
        # this means no new events were generated and you can use the event cache.
        $groupedEvents=$Script:LatestGroupedEvents[$Script:ThisComputerName]
    }
    else
    {
        
        #Save it to cache
        $allEvents=Get-AllDscEvents
        if(!$allEvents)
        {
            Log -Error "Error : Could not find any events. Either a DSC operation has not been run, or the event logs are turned off . Please ensure the event logs are turned on in DSC. To set an event log, run the command wevtutil Set-Log <channelName> /e:true, example: wevtutil set-log 'Microsoft-Windows-Dsc/Operational' /e:true /q:true"
            return
        }
        $groupedEvents= $allEvents | Group {$_.Properties[0].Value} 
    
        $Script:MostRecentJobId[$Script:ThisComputerName]=$latestJobId
        $Script:LatestGroupedEvents[$Script:ThisComputerName] =$groupedEvents
    }

    #group based on their Job Ids
    return $groupedEvents
}

#Wrapper over get-winevent, that will call into a computer if required.
 function get-winevent
 {
    $resultArray=""
    try
    {
         if($Script:UsingComputerName)
        {
        
            if($Script:ThisCredential)
            {
                $resultArray=Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $Script:ThisComputerName -Credential $Script:ThisCredential
            }
            else
            {
                $resultArray= Microsoft.PowerShell.Diagnostics\Get-WinEvent @args -ComputerName $Script:ThisComputerName
            }
        }
    
        else
        {
           $resultArray= Microsoft.PowerShell.Diagnostics\Get-WinEvent @args
        }
    }
    catch
    {
        Log -Error "Get-Winevent failed with error : $_ "
        throw "Cannot read events from computer $Script:ThisComputerName. Please check if the firewall is enabled. Run this command in the remote machine to enable firewall for remote administration : netsh firewall set service remoteadmin enable "
    }
    return $resultArray

}
 #Gets the JOB ID of the most recently executed script.
 function Get-DscLatestJobId
 {
    
    #Collect operational events , they're ordered from newest to oldest.
    
    $allevents=get-winevent -LogName "$Script:DscLogName/operational" -MaxEvents 2 -ea Ignore
    if($allevents -eq $null)
    {
        return "NOJOBID"
    }
    $latestEvent=$allevents[0] #Since it extracts it in a sorted order.

    #Extract just the jobId from the string like : Job : {<jobid>}
    #$jobInfo=(((($latestEvent.Message -split (":",2))[0] -split "job {")[1]) -split "}")[0]
    $jobInfo=$latestEvent.Properties[0].value
        
    return $jobInfo.ToString()
 }

 #Function to get all dsc events in the event log - not exposed by the module
 function Get-AllDscEvents
 {
    #If you want a specific channel events, run it as Get-AllDscEvents 
    param
    (  
       [string[]]$ChannelType=@("Debug","Analytic","Operational") ,
       $OtherParams=@{}
       
    )
    if($ChannelType.ToLower().Contains("operational")) 
    { 
        
        $operationalEvents=get-winevent -LogName "$Script:DscLogName/operational"  @OtherParams -ea Ignore
        $allevents=$operationalEvents
    
    }
    if($ChannelType.ToLower().Contains("analytic"))
    {
        $analyticEvents=get-winevent -LogName "$Script:DscLogName/analytic" -Oldest  -ea Ignore @OtherParams
        if($analyticEvents -ne $null)    
        { 

                #Convert to an array type before adding another type - to avoid the error "Method invocation failed with no op_addition operator"
                $allevents = [System.Array]$allEvents + $analyticEvents
            
        }
        
    }

    if($ChannelType.ToLower().Contains("debug"))
    {
        $debugEvents=get-winevent -LogName "$Script:DscLogName/debug" -Oldest -ea Ignore @OtherParams
        if($debugEvents -ne $null)    
        { 
                $allevents = [System.Array]$allEvents +$debugEvents
                         
        }
    }
    
    return $allevents
 }


 #  Function to prompt the user to set an event log, for the channel passed in as parameter
 #
 function Test-DscEventLogStatus
 {
    param($Channel="Analytic")
    $LogDetails=Get-WinEvent -ListLog "$Script:DscLogName/$Channel"
    if($($LogDetails.IsEnabled))
    {
        return $true
    }
    $numberOfTries=0;
    while($numberOfTries -lt 3)
    {
        $enableLog=Read-Host "The $Channel log is not enabled. Would you like to enable it?(y/n)"
        if($enableLog.ToLower() -eq "y")
        {
            Enable-DscEventLog -Channel $Channel
            Write-Host "Execute the operation again to record the events. Events were not recorded in the $Channel channel since it was disabled"
            break
        }

        elseif($enableLog.ToLower() -eq "n")
        {
            Log -Error "The $Channel events cannot be read until it has been enabled" 
            break
        }
        else
        {
            Log -Error "Could not understand the option, please try again" 
        }
        $numberOfTries++
    }
    return $false

 }

 #This function gets all the DSC runs that are recorded into the event log.
 function Get-SingleDscOperation
 {
    #If you specify a sequence ID, then the diagnosis will be for that sequence ID.
    param(
          [Uint32]$indexInArray=0,
          [Guid]$JobId
          )

    #Get all events 
    $groupedEvents=Get-AllGroupedDscEvents
    if(!$groupedEvents)
    {
        return
    }
    #If there is a job ID present, ignore the IndexInArray, search based on jobID
    if($JobId)
    {
        Log -Verbose "Looking at Event Trace for the given Job ID $JobId"
        $indexInArray=0;
        foreach($eventGroup in $groupedEvents)
        {

            #Check if the Job ID is present in any 
            if($($eventGroup.Name) -match $JobId)
            {
                break;
            }
            $indexInArray ++
        }
        if($indexInArray -ge $groupedEvents.Count)
        {

            #This means the job id doesn't exist
            Log -Error "The Job ID Entered $JobId, does not exist among the dsc operations. To get a list of previously run DSC operations, run this command : Get-cDscOperation"
            return
        }
    }
    $requiredRecord=$groupedEvents[$indexInArray]
    if($requiredRecord -eq $null)
    {
        Log -Error "Could not obtain the required record! "
        return
    }
    $errorText="[None]"
    $thisRunsOutputEvents=Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $requiredRecord -index $indexInArray
        
    $thisRunsOutputEvents

 }
  
 function Split-SingleDscGroupedRecord
 {
    param(
    $singleRecordInGroupedEvents,
    $index)
            
            #$singleOutputRecord=New-Object psobject 
            $status=$Script:SuccessResult
            $errorEvents=@()
            $col_AllEvents=@()
            $col_verboseEvents=@()
            $col_analyticEvents=@()
            $col_debugEvents=@()
            $col_operationalEvents=@()
            $col_warningEvents=@()
            $col_nonVerboseEvents=@()

            #We want to now add a column for each event that says "staus as success or failure"
            $oneGroup= $singleRecordInGroupedEvents.Group
            $column_Time=$oneGroup[0].TimeCreated
            $oneGroup| %{
                $thisEvent=$_
                $thisType=""
                $timeCreatedOfEvent=$_.TimeCreated
               
                if($_.level -eq 2) #which means there's an error
                {
                    $status="$Script:FailureResult"
                    $errorEvents += $_
                    $thisType= [Microsoft.PowerShell.cDscDiagnostics.EventType]::ERROR
                    
                }
                elseif($_.LevelDisplayName -like "warning") { $col_warningEvents +=$_ }
                if($_.ContainerLog.endsWith("operational")) 
                { 
                    $col_operationalEvents+=$_ ; 
                    $col_nonVerboseEvents += $_ 

                    #Only if its not an error message, mark it as OPerational tag
                    if(!$thisType)
                    {$thisType=[Microsoft.PowerShell.cDscDiagnostics.EventType]::OPERATIONAL}
                }
                elseif($_.ContainerLog.endsWith("debug")) { $col_debugEvents+=$_ ; $thisType = [Microsoft.PowerShell.cDscDiagnostics.EventType]::DEBUG }
                elseif($_.ContainerLog.endsWith("analytic")) 
                { 
                    $col_analyticEvents+=$_  
                    if($_.Id -in $Script:DscVerboseEventIdsAndPropertyIndex.Keys)
                    {
                        $col_verboseEvents +=$_
                        $thisType=[Microsoft.PowerShell.cDscDiagnostics.EventType]::VERBOSE
                    
                    }
                    else
                    {
                        $col_nonVerboseEvents += $_
                        $thisType=[Microsoft.PowerShell.cDscDiagnostics.EventType]::ANALYTIC
                    
                    }
                }
                $eventMessageFromEvent=Get-MessageFromEvent $thisEvent -verboseType
                #Add event with its tag 

                $thisObject= New-Object PSobject -Property @{TimeCreated=$timeCreatedOfEvent; Type=$thisType; Event=$thisEvent; Message = $eventMessageFromEvent}
                $col_AllEvents  += $thisObject
                
            }

            $jobIdWithoutParenthesis=($($singleRecordInGroupedEvents.Name).split('{}'))[1] #Remove paranthesis that comes in the job id
            if(!$jobIdWithoutParenthesis) {$jobIdWithoutParenthesis=$null}

            $singleOutputRecord = new-object Microsoft.PowerShell.cDscDiagnostics.GroupedEvents -property @{
                   SequenceID=$index;
                   ComputerName=$Script:ThisComputerName;
                   JobId=$jobIdWithoutParenthesis;
                   TimeCreated=$column_Time;
                   AllEvents=$col_AllEvents | Sort-Object TimeCreated;
                   AnalyticEvents=$col_analyticEvents ;
                   WarningEvents=$col_warningEvents | Sort-Object TimeCreated ;
                   OperationalEvents=$col_operationalEvents;
                   DebugEvents=$col_debugEvents ;
                   VerboseEvents=$col_verboseEvents  ;
                   NonVerboseEvents=$col_nonVerboseEvents | Sort-Object TimeCreated;
                   ErrorEvents=$errorEvents;
                   Result=$status;
                   NumberOfEvents=$singleRecordInGroupedEvents.Count;}

            
            return $singleOutputRecord
 }

 function Get-MessageFromEvent($EventRecord,[switch]$verboseType)
 {
    
    #You need to remove the job ID and send back the message
    if($EventRecord.Id -in $Script:DscVerboseEventIdsAndPropertyIndex.Keys -and $verboseType)
    {
        $requiredIndex=$Script:DscVerboseEventIdsAndPropertyIndex[$($EventRecord.Id)]
        return $EventRecord.Properties[$requiredIndex].Value
    }
    
    $NonJobIdText=($EventRecord.Message -split([Environment]::NewLine,2))[1]

   
    return $NonJobIdText
    
 }


 function Get-DscErrorMessage
 {
    param(<#[System.Diagnostics.Eventing.Reader.EventRecord[]]#>$ErrorRecords)
    $cimErrorId=4131
    
    $errorText=""
    foreach($Record in $ErrorRecords)
    {
        #go through each record, and get the single error message required for that record.
        $outputErrorMessage=Get-SingleRelevantErrorMessage -errorEvent $Record
        if($Record.Id -eq $cimErrorId)
        {
            $errorText = "$outputErrorMessage $errorText"
        }
        else
        {
            $errorText = "$errorText $outputErrorMessage"
        }
    }
    return  $errorText

}

 
 <#
.SYNOPSIS 
Sets any DSC Event log (Operational, analytic, debug )

.DESCRIPTION
This cmdlet will set a DSC log when run with Enable-DscEventLog <channel Name>.

.PARAMETER Channel
Name of the channel of the event log to be set.

.EXAMPLE
C:\PS> Enable-DscEventLog "Analytic" 
C:\PS> Enable-DscEventLog -Channel "Debug"
#>
 function Enable-DscEventLog
 {
    param(
        $Channel="Analytic"
    )

    $LogName="Microsoft-Windows-Dsc"

	$eventLogFullName="$LogName/$Channel"
    try
    {
        Log -Verbose "Enabling the log $eventLogFullName"
        if($Script:ThisComputerName -eq $env:COMPUTERNAME)
        {
            wevtutil set-log $eventLogFullName /e:true /q:true    
        }
        else
        {

            #For any other computer, invoke command./ 
            $scriptTosetChannel=[Scriptblock]::Create(" wevtutil set-log $eventLogFullName /e:true /q:true")
            
            if($Script:ThisCredential)
            {
                Invoke-Command -ScriptBlock $scriptTosetChannel -ComputerName $Script:ThisComputerName  -Credential $Script:ThisCredential
            }
            else
            {
                Invoke-Command -ComputerName $Script:ThisComputerName -ScriptBlock $scriptTosetChannel
            }
        }
        Write-Host "The $Channel event log has been Enabled. "
    }
    catch
    {
        Log -Error "Error : $_ "
    }

 }
 
 function Get-SingleRelevantErrorMessage(<#[System.Diagnostics.Eventing.Reader.EventRecord]#>$errorEvent)
 {
    $requiredPropertyIndex=@{4116=2;
                         4131=1;
                         4183 =-1;#means full message
                         4129=-1;
                         4192=-1;
                         4193=-1;
                         4194=-1;
                         4185=-1;
                         4097=6;
                         4103=5;
                         4104=4}
    $cimErrorId=4131
    $errorText=""
    $outputErrorMessage=""
    $eventId=$errorEvent.Id
    $propertyIndex=$requiredPropertyIndex[$eventId]
    if($propertyIndex -ne -1)
    {

        #This means You need just the property from the indices hash
        $outputErrorMessage=$errorEvent.Properties[$propertyIndex].Value

    }
    else
    {
        $outputErrorMessage=Get-MessageFromEvent -EventRecord $errorEvent
    }
    return $outputErrorMessage
    
}

 function Trace-DscOperationInternal
 {
    [cmdletBinding()]
    param(
        [UInt32]$SequenceID=1, #latest is by default
        [Guid]$JobId
        
        )
    

    #region VariableChecks
    $indexInArray= ($SequenceId-1); #Since it is indexed from 0

    if($indexInArray -lt 0)
    {
        Log -Error "Please enter a valid Sequence ID . All sequence IDs can be seen after running command Get-cDscOperation . " -ForegroundColor Red
        return
    } 
    $null=Test-DscEventLogStatus -Channel "Analytic" 
    $null=Test-DscEventLogStatus -Channel "Debug"
    
    #endregion

    #First get the whole object set of that operation
    $thisRUnsOutputEvents=""
    if(!$JobId)
    {
        $thisRunsOutputEvents=Get-SingleDscOperation -IndexInArray $indexInArray 
    }
    else
    {
        $thisRunsOutputEvents=Get-SingleDscOperation -IndexInArray $indexInArray -JobId $JobId
    }
    if(!$thisRunsOutputEvents)
    {
        return;
    }

    #Now we play with it.
    $result=$thisRunsOutputEvents.Result

        #Parse the error events and store them in error text.
        $errorEvents= $thisRunsOutputEvents.ErrorEvents 
        $errorText = Get-DscErrorMessage -ErrorRecords  $errorEvents 
        
       #Now Get all logs which are non verbose 
        $nonVerboseMessages=@()
       
        $AllEventMessageObject=@()
        $thisRunsOutputEvents.AllEvents | %{
                                $ThisEvent=  $_.Event
                                $ThisMessage= $_.Message
                                $ThisType=  $_.Type
                                $ThisTimeCreated= $_.TimeCreated
                                #Save a hashtable as a message value 
                                if(!$thisRunsOutputEvents.JobId) {$thisJobId=$null}
                                else {$thisJobId=$thisRunsOutputEvents.JobId}
                                $AllEventMessageObject +=   new-object Microsoft.PowerShell.cDscDiagnostics.TraceOutput -Property @{EventType=$ThisType;TimeCreated=$ThisTimeCreated;Message=$ThisMessage;ComputerName=$Script:ThisComputerName;JobID=$thisJobId;SequenceID=$SequenceID;Event=$ThisEvent}
                                
                            } 
       
        
        return $AllEventMessageObject
        
}

 #Internal function called by Get-cDscOperation
 function Get-DscOperationInternal()
 {
    param
    ([UInt32]$Newest = 10)
        #Groupo all events
        $groupedEvents=Get-AllGroupedDscEvents
    
        $DiagnosedGroup =$groupedEvents

        #Define the type that you want the output in
       
        $index=1
        foreach($singleRecordInGroupedEvents in $DiagnosedGroup)
        {
            $singleOutputRecord=Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -index $index
            $singleOutputRecord
            if($index -ge $Newest)
            {
                break;
            }
            $index++
              
        }
 }
 
#endregion


 
 function Clear-DscDiagnosticsCache
 {
    Log -Verbose "Clearing Diagnostics Cache"
    $Script:LatestGroupedEvents=@{}
    $Script:MostRecentJobId=@{}

 }
 

Export-ModuleMember -Function Trace-cDscOperation, Get-cDscOperation