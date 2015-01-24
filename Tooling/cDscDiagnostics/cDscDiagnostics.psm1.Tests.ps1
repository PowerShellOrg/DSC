Remove-Module [c]DscDiagnostics
Import-Module $PSScriptRoot\cDscDiagnostics.psm1

Describe "Trace-cDscOperation" {
    Context "does it call its internal functions" {
        Mock -ModuleName cDscDiagnostics Add-ClassTypes {}
        Mock -ModuleName cDscDiagnostics Trace-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Trace-cDscOperation -ComputerName $env:ComputerName;

        It "should call Add-ClassType" {
            Assert-MockCalled Add-ClassTypes -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Trace-DscOperationInternal" {
            Assert-MockCalled Trace-DscOperationInternal -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Log" {
            Assert-MockCalled Log -ModuleName cDscDiagnostics -Times 1
        }
    }
}

Describe "Add-ClassTypes" {
    Context "when its called" {
        Mock -ModuleName cDscDiagnostics Update-FormatData {}
        Mock -ModuleName cDscDiagnostics Trace-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Trace-cDscOperation -ComputerName $env:ComputerName;

        It "should have loaded it's event types" {
            { [Microsoft.PowerShell.cDscDiagnostics.EventType]::ANALYTIC } | Should Not Throw
        }

        It "should have loaded it's group events" {
            { [Microsoft.PowerShell.cDscDiagnostics.GroupedEvents] } | Should Not Throw
        }
    }
}

InModuleScope cDscDiagnostics {
    Describe 'Log' {
        It 'Should write verbosely' {
            $text = "Verbose Text"
            $verboseLog = Log $text -Verbose 4>&1
            $verboseLog | Should Be $text
        }

        It 'should write errors' {
            $text = "Error Text"
            $errorLog = Log $text -Error 2>&1
            $errorLog | Should Be $text
        }

        BeforeEach {
            $vPreference = $VerbosePreference;
            $ePreference = $ErrorActionPreference;

            $VerbosePreference = "Continue";
            $ErrorActionPreference = "Continue";
        }

        AfterEach {
            $VerbosePreference = $vPreference;
            $ErrorActionPreference = $ePreference;
        }
    }

    Describe 'Trace-DscOperationInternal' {
        Context 'SequenceID is passed' {
            Mock Log { }
            $result = Trace-DscOperationInternal -SequenceID 0;

            It 'should return null if SequenceID is less then 1' {
                $result | Should Be $null;
            }

            $date = Get-Date;
            $message = "Some Message";
            # Choosing Application because we need /something/ here and we can't assume that the machine has run a DSC command.
            $event = Get-WinEvent -LogName Application -MaxEvents 1

            $traceOutput = New-Object PSObject -Property @{
                Type = "Operational";
                TimeCreated = $date;
                Message = $message;
                ComputerName = $env:ComputerName;
                SequenceID = 2;
                Event = $event;
            }

            Mock Get-SingleDscOperation { return @{
                    AllEvents = $traceOutput;
                    ErrorEvents = "SomeEvent";
                    JobId = "54137c5a-f607-48a5-9311-d6e102c15f83";
                }
            }

            Mock Test-DscEventLogStatus { }
            Mock Get-DscErrorMessage { return "Error Text" }

            $result = Trace-DscOperationInternal -SequenceID 2;

            It 'should do call Test-DscEventLogStatus' {
                Assert-MockCalled Test-DscEventLogStatus -Times 2
            }

            It 'should call Get-SingleDscOperation' {
                Assert-MockCalled Get-SingleDscOperation -Times 1
            }

            It 'should call Get-DscErrorMessage' {
                Assert-MockCalled Get-DscErrorMessage -Times 1
            }

            It 'should return the correct event type' {
                $result.EventType | Should Be "Operational";
            }

            It 'should return the correct time' {
                $result.TimeCreated | Should Be $date;
            }

            It 'should return the correct message' {
                $result.Message | Should Be $message;
            }

            It 'should return the correct machine' {
                $result.ComputerName | Should Be $env:ComputerName;
            }

            It 'should return the correct SequenceID' {
                $result.SequenceID | Should Be 2;
            }

            It 'should return the correct Event' {
                $result.Event | Should Be $event;
            }
        }

        Context 'JobId Passed' {
            $date = Get-Date;
            $message = "Some Message";
            # Choosing Application because we need /something/ here and we can't assume that the machine has run a DSC command.
            $event = Get-WinEvent -LogName Application -MaxEvents 1

            $traceOutput = New-Object PSObject -Property @{
                Type = "Operational";
                TimeCreated = $date;
                Message = $message;
                ComputerName = $env:ComputerName;
                SequenceID = 1;
                Event = $event;
            }

            Mock Get-SingleDscOperation { return @{
                    AllEvents = $traceOutput;
                    ErrorEvents = "SomeEvent";
                    JobId = "54137c5a-f607-48a5-9311-d6e102c15f83";
                }
            }

            Mock Test-DscEventLogStatus { }
            Mock Get-DscErrorMessage { return "Error Text" }

            $result = Trace-DscOperationInternal -SequenceID 1 -JobId "54137c5a-f607-48a5-9311-d6e102c15f83";

            It 'should return the Job Id' {
                $result.JobId | Should Be "54137c5a-f607-48a5-9311-d6e102c15f83"
            }
        }

        Context 'Get-SingleDscOperation returns null' {
            Mock Test-DscEventLogStatus { }
            Mock Get-SingleDscOperation { }

            $result = Trace-DscOperationInternal -SequenceID 1 -JobId "54137c5a-f607-48a5-9311-d6e102c15f83";

            It 'should return null' {
                $result | Should Be $null;
            }
        }

        # This way we don't cache anything while testing.
        AfterEach {
            Clear-DscDiagnosticsCache
        }
    }

    Describe 'Get-DscLatestJobId' {
        Context 'It has a Job to Return' {
            Mock Get-WinEvent {
                $value = @{"Value" = "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"}
                $returnObject = @(@{Properties = @($value)}, [Environment]::NewLine)
                return @(@{Properties = @($value)}, [Environment]::NewLine)
            }

            $result = Get-DscLatestJobId;

            It 'should return the GUID' {
                $result | Should Be "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"
            }
        }

        Context 'When it does not have a Job' {
            Mock Get-WinEvent {
                return $null
            }

            $result = Get-DscLatestJobId;

            It 'should return "NOJOBID"' {
                $result | Should Be "NOJOBID"
            }
        }

        AfterEach {
            Clear-DscDiagnosticsCache
        }
    }

    Describe 'Get-AllDscEvents' {
        Mock Get-WinEvent {
            Microsoft.PowerShell.Diagnostics\Get-WinEvent -LogName Application -MaxEvents 1
        }

        $result = Get-AllDscEvents;

        It 'should do call Get-WinEvent for each log passed' {
            Assert-MockCalled Get-WinEvent -Times 3
            $result.Count | Should Be 3
        }

        It 'should return something' {
            $result | Should Not Be $null;
        }
    }

    Describe 'Get-AllGroupedDscEvents' {
        Context 'Get-AllDscEvents returns null' {
            Mock Get-AllDscEvents {}
            Mock Get-DscLatestJobId {return "NOJOBID"}
            Mock Log {}
            $result = Get-AllGroupedDscEvents;

            It "should call Log" {
                Assert-MockCalled Log -Times 1
            }

            It 'should call Get-DscLatestJobId' {
                Assert-MockCalled Get-DscLatestJobId -Times 1
            }

            It 'should return null' {
                $result | Should Be $null
            }
        }

        Context 'Get-AllDscEvents returns events' {
            $value = @{"Value" = "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"}
            Mock Get-AllDscEvents {return @{Properties = @($value)}}
            Mock Log {}
            Mock Get-DscLatestJobId { return 'MOCKEDJOBID' }
            $result = Get-AllGroupedDscEvents

            It 'should return a specific event' {
                $result.Name | Should Be "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"
            }
        }

        Context 'Cached Events' {
            Mock Get-DscLatestJobId { return 'MOCKEDJOBID' }
            Mock Get-AllDscEvents {}

            $result = Get-AllGroupedDscEvents;

            It 'should return a specific event' {
                Assert-MockCalled Get-AllDscEvents -Scope It -Times 0
                $result.Name | Should Be "{3BBB79B7-BD46-424C-9718-983C8C76D37E}"
            }
        }
    }

    Describe 'Get-SingleDscOperation' {
        Context 'Get-AllGroupedDscEvents is empty' {
            Mock Get-AllGroupedDscEvents {}

            $result = Get-SingleDscOperation;

            It 'should return empty' {
                $result | Should BeNullorEmpty
            }
        }

        Context 'JobId is Passed but its not found' {
            Mock Log {}
            Mock Get-AllGroupedDscEvents {@{Name = "NOJOBID"}}
            $result = Get-SingleDscOperation -JobId 3BBB79B7-BD46-424C-9718-983C8C76D37E

            It 'should return empty' {
                $result | Should BeNullorEmpty
            }
        }

        Context 'JobId is passed and found' {
            Mock Log {}
            Mock Get-AllGroupedDscEvents {
                return New-Object PSObject -Property @{
                    Name = New-Object PSObject -Property @{
                        Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    }

                    Count = 1
                }
            }

            Mock Split-SingleDscGroupedRecord { $true }

            $result = Get-SingleDscOperation -JobId 3BBB79B7-BD46-424C-9718-983C8C76D37E

            It 'should have called Get-SingleDscOperation' {
                Assert-MockCalled Split-SingleDscGroupedRecord -Times 1
                $result | Should Be $true
            }
        }
    }

    Describe 'Split-SingleDscGroupedRecord' {
        Context 'Passed an bad DSC record' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 2;
                    ContainerLog = "Microsoft-Windows-Dsc/Operational";
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
                Count = 1
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            It 'should have SequenceID match the index' {
                $result.SequenceID | Should Be 0
            }

            It 'should have ComputerName match this computer' {
                $result.ComputerName | Should Be $env:ComputerName
            }

            It 'should have a failure as the result' {
                $result.Result | Should Be "Failure"
            }

            It 'should have error as the type' {
                $result.AllEvents[0].Type | Should Be "ERROR"
            }

            It 'should have the mocked message' {
                $result.AllEvents[0].Message | Should Be "Mocked Message"
            }

            It 'should have the right JobId' {
                $result.JobId | Should Be "54137C5A-F607-48A5-9311-D6E102C15F83"
            }

            It 'should have the right count' {
                $result.NumberOfEvents | Should Be 1
            }
        }

        Context 'Passing a Warning' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 1;
                    ContainerLog = "Microsoft-Windows-Dsc/Operational";
                    LevelDisplayName = "Warning";
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            it 'should find a warning event' {
                $result.WarningEvents | Should Not Be $null
            }
        }

        Context 'Passing an Operational Log' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 1;
                    ContainerLog = "Microsoft-Windows-Dsc/operational";
                    LevelDisplayName = "Operational";
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            It 'should find the right type' {
                $result.AllEvents[0].Type | Should Be "OPERATIONAL"
            }

            It 'should find some operational events' {
                $result.OperationalEvents | Should Not Be $null
            }

            It 'should find some non-verbose events' {
                $result.NonVerboseEvents | Should Not Be $null
            }
        }

        Context 'Passing a Debug Log' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 1;
                    ContainerLog = "Microsoft-Windows-Dsc/debug";
                    LevelDisplayName = "Debug";
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            It 'should find the right type' {
                $result.AllEvents[0].Type | Should Be "DEBUG"
            }

            It 'should find some debug events' {
                $result.DebugEvents | Should Not Be $null
            }
        }

        Context 'Passing a Verbose Log' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 1;
                    ContainerLog = "Microsoft-Windows-Dsc/analytic";
                    LevelDisplayName = "analytic";
                    Id = 4100;
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            It 'should find the right type' {
                $result.AllEvents[0].Type | Should Be "Verbose"
            }

            It 'should find some debug events' {
                $result.VerboseEvents | Should Not Be $null
            }
        }

        Context 'Passing an Analytic Log' {
            $TimeCreated = Get-Date;
            $singleRecordInGroupedEvents = New-Object PSObject -Property @{
                Group = New-Object PSObject -Property @{
                    Guid = "3bbb79b7-bd46-424c-9718-983c8c76d37e"
                    TimeCreated = $TimeCreated;
                    Level = 1;
                    ContainerLog = "Microsoft-Windows-Dsc/analytic";
                    LevelDisplayName = "analytic";
                }
                Name = "{54137C5A-F607-48A5-9311-D6E102C15F83}"
            }

            Mock Get-MessageFromEvent {return "Mocked Message"}

            $result = Split-SingleDscGroupedRecord -singleRecordInGroupedEvents $singleRecordInGroupedEvents -Index 0;

            It 'should find the right type' {
                $result.AllEvents[0].Type | Should Be "Analytic"
            }

            It 'should find some analytic events' {
                $result.NonVerboseEvents | Should Not Be $null
            }
        }
    }

    Describe 'Get-MessageFromEvent' {
        Context 'For a non-verbose event' {
            $eventRecord = New-Object PSObject -Property @{
                Message = [Environment]::NewLine + "Some Message";
            }

            $result = Get-MessageFromEvent -EventRecord $eventRecord

            It 'should return the value' {
                $result | Should Be "Some Message"
            }
        }

        Context 'For a verbose event' {
            $verboseMessage = New-Object PSObject -Property @{Value = "Verbose Message"}
            $value = @([Environment]::NewLine, [Environment]::NewLine, $verboseMessage)
            $eventRecord = New-Object PSObject -Property @{
                Message = [Environment]::NewLine + "Some Message";
                Id = 4117
                Properties = $value;
            }

            $result = Get-MessageFromEvent -EventRecord $eventRecord -verboseType

            It 'should return the value' {
                $result | Should Be "Verbose Message"
            }
        }
    }

    Describe 'Get-DscErrorMessage' {
        Mock Get-SingleRelevantErrorMessage {return "Output Error Message"}
        $errorRecords = @{Id = "4131";}

        $result = Get-DscErrorMessage -ErrorRecords $errorRecords

        It 'should be the message' {
            $result | should be "Output Error Message "
        }
    }

    Describe 'Get-SingleRelevantErrorMessage' {
        Context 'Property Index is -1' {
            $value = @{Value = "Property"}
            $hash = @([Environment]::NewLine; $value)
            $errorEvent = @{Id = 4131; Properties = $hash}

            $result = Get-SingleRelevantErrorMessage -ErrorEvent $errorEvent;

            It 'should reutrn the correct string' {
                $result | should be "Property"
            }
        }

        Context 'Property Index is not -1' {
            Mock Get-MessageFromEvent {return "Mocked Message"}

            $value = @{Value = "Property"}
            $hash = @([Environment]::NewLine; $value)
            $errorEvent = @{Id = 4183; Properties = $hash}

            $result = Get-SingleRelevantErrorMessage -ErrorEvent $errorEvent;

            It 'should call Get-MessageFromEvent' {
                Assert-MockCalled Get-MessageFromEvent 
            }

            It 'should reutrn the correct string' {
                $result | should be "Mocked Message"
            }
        }
    }

    Describe 'Get-DscOperationInternal' {
        Mock Get-AllGroupedDscEvents { return "GroupedEvents" }
        Mock Split-SingleDscGroupedRecord  { return "singleOutputRecord" }

        $result = Get-DscOperationInternal -Newest 1;

        It 'should call Get-AllGroupedDscEvents' {
            Assert-MockCalled Get-AllGroupedDscEvents 
        }

        It 'should loop over the events the correct amount of times' {
            Assert-MockCalled Split-SingleDscGroupedRecord -Times 1
        }

        It 'should return the singleOutputRecord' {
            $result | Should Be "singleOutputRecord"
        }
    }

    Describe 'Test-DscEventLogStatus' {
        Context 'Log is Enabled' {
            Mock Get-WinEvent {return @{IsEnabled = $true}}
            $result = Test-DscEventLogStatus

            It 'should return true' {
                $result | Should Be $true
            }
        }

        Context 'Log is Disabled and not enabled' {
            Mock Get-WinEvent {return @{IsEnabled = $false}}
            Mock Log {}
            Mock Read-Host {return "n"};

            $result = Test-DscEventLogStatus

            It 'should return false' {
                $result | Should Be $false
            }

            It 'should call Log' {
                Assert-MockCalled Log 
            }

            It 'should call Read-Host' {
                Assert-MockCalled Read-Host 
            }
        }

        Context 'Log is Disabled and is enabled' {
            Mock Get-WinEvent {return @{IsEnabled = $false}}
            Mock Enable-DscEventLog {}
            Mock Read-Host {return "y"};
            Mock Write-Host {};

            $result = Test-DscEventLogStatus

            It 'should return false' {
                $result | Should Be $false
            }

            It 'should call Write-Host' {
                Assert-MockCalled Write-Host 
            }

            It 'should call Read-Host' {
                Assert-MockCalled Read-Host 
            }

            It 'should call Enable-DscEventLog' {
                Assert-MockCalled Enable-DscEventLog 
            }
        }
    }
}

Describe "Get-cDscOperation" {
    Context "does it call its internal functions" {
        Mock -ModuleName cDscDiagnostics Add-ClassTypes {}
        Mock -ModuleName cDscDiagnostics Get-DscOperationInternal {}
        Mock -ModuleName cDscDiagnostics Log {}

        $result = Get-cDscOperation -ComputerName $env:ComputerName;

        It "should call Add-ClassType" {
            Assert-MockCalled Add-ClassTypes -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Get-DscOperationInternal" {
            Assert-MockCalled Get-DscOperationInternal -ModuleName cDscDiagnostics -Times 1
        }

        It "should call Log" {
            Assert-MockCalled Log -ModuleName cDscDiagnostics -Times 1
        }
    }
}