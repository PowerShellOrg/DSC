Example DSC Build
------

This folder contains some very basic examples of what a DSC configurationData folder structure, script, and call to Invoke-DscBuild might look like.  If you want to execute SampleBuild.ps1, there are a few dependencies you need to set up ahead of time:

- You must install all of the DSC tooling modules from this repository into your PSModulePath (typically into C:\Program Files\WindowsPowerShell\Modules\)
- You must also copy the Tooling\Examples\SampleConfiguration folder to the PSModulePath.
- You must copy [Pester](https://github.com/pester/Pester) (version 3.0.0 or later) into the PSModulePath.
- You should create a DSC_Resources folder in the same directory as SampleBuild.ps1 and DSC_Configuration.  Copy the following modules into that DSC_Resources folder:
  - [StackExchangeResources](https://github.com/PowerShellOrg/StackExchangeResources)
  - [cWebAdministration](https://github.com/PowerShellOrg/cWebAdministration)
  - [cSmbShare](https://github.com/PowerShellOrg/cSmbShare)

Once these dependencies are set up, you can execute SampleBuild.ps1.  It will run tests against the 3 modules in your DSC_Resources folder, compile your configuration into MOF documents, produce zip files for the resource modules, generate checksums for everything and copy them into C:\Program Files\WindowsPowerShell\DscService\

_Note:  The SampleBuild.ps1 file currently just dumps DSC_Tooling modules into the temporary folder, since I wasn't using that feature.  We'll build on these examples soon to show off some of the other functionality in the DscBuild and DscConfiguration modules, such as encrypting credentials in source control._
