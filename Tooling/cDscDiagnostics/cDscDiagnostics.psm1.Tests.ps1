Import-Module .\cDscDiagnostics.psm1

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