@{

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '04418a65-782d-4a8f-a4e1-6a8ea078a880'

# Author of this module
Author = 'Craig Martin'

# Company or vendor of this module
CompanyName = 'PowerShell.org'

# Copyright statement for this module
Copyright = '(c) 2013 PowerShell.org. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This Module is used to support the execution of query, install & uninstall functionalities on local global assembly cache items through Get, Set and Test API on the DSC managed nodes.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '4.0'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @("GlobalAssemblyCache.psm1")

# Functions to export from this module
FunctionsToExport = @("Get-TargetResource", "Set-TargetResource", "Test-TargetResource")

# HelpInfo URI of this module

# HelpInfoURI = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @("gac")

}


