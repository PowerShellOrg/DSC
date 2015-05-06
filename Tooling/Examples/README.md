Example DSC Build
------

This folder contains some very basic examples of what a DSC configurationData folder structure, script, and call to Invoke-DscBuild might look like.  If you want to execute SampleBuild.ps1, there are a few dependencies you need to set up ahead of time:

- You must install all of the DSC tooling modules (content of \Tools minus the example folder) from this repository into your PSModulePath (typically into C:\Program Files\WindowsPowerShell\Modules\)
- You must also copy the Tooling\Examples\SampleConfiguration folder to the PSModulePath.
- You must copy [Pester](https://github.com/pester/Pester) (version 3.0.0 or later) and [ProtectedData](https://github.com/dlwyatt/ProtectedData) (version 2.1 or later) into the PSModulePath.
- You should create a DSC_Resources folder in the same directory as SampleBuild.ps1 and DSC_Configuration.  Copy the following modules into that DSC_Resources folder:
  - [StackExchangeResources](https://github.com/PowerShellOrg/StackExchangeResources)
  - [cWebAdministration](https://github.com/PowerShellOrg/cWebAdministration)
  - [cSmbShare](https://github.com/PowerShellOrg/cSmbShare)

Create a folder to place all the files into. i.e. c:\DSC, inside that folder create folders named BuildOutput, DSC_Configuration, DSC_Resorces, DSC_Script, DSC_Tooling. 

the folder structure should look like this
C:\DSC                # copy SampleBuild.ps1 here
+---BuldOutput        # Where the MOF files and ziped modules end up
+---DSC_Configuration # Copy \Tooling\Examples\DSC_Configuration\*  here
+---DSC_Resources     # copy StackExchangeResources, cSmbShare and cWebAdministration here
+---DSC_Script        # copy \Tooling\Examples\SampleConfiguration here
+---DSC_Tooling       # This is for any modules that may be used in a Configuration script, in the case of SampleConfiguration it would be empty.

If you plan on modifying SampleConfiguration.psm1 inside of DSC_Script you will also want to add the content of DSC_Modules to C:\Program Files\WindowsPowerShell\Modules\ but that is not necessary if your just building configurations that are authored on another machine. 

Once these dependencies are set up, you can execute SampleBuild.ps1.  It will run tests against the 3 modules in your DSC_Resources folder, compile your configuration into MOF documents, produce zip files for the resource modules, generate checksums for everything and copy them into BuildOutput

_Note:  The SampleBuild.ps1 file currently just dumps DSC_Tooling modules into the temporary folder, since I wasn't using that feature.  We'll build on these examples soon to show off some of the other functionality in the DscBuild and DscConfiguration modules, such as encrypting credentials in source control._
