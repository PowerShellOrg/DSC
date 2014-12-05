# BIG CHANGES

We have moved the DSC Resources into their own repositories under PowerShell.Org.

## Why?
* To make it easier to track issues for individual resources
* To allow more community members to participate in the maintence of these resources
* To make it easier to automate publishing of individual resources to PowerShellGet and other sources

## How can I contribute?

### If you have a new resource you want to share, 
* File an issue here and let us know what the name of the project should be.  
* We'll create a repository and make you an contributor (if you want) to that repository. 
* You can then populate that repository via a pull request or we can clone an existing repository in the organization.
or
* You can create a gist containing the files for your DSC resource and we can move them into a repository.

### If you want to help maintain an existing resource
* Start by contributing something.. a bugfix, documentation, file issues
* After a contribution or two, file an issue requesting to become a maintainer for the project
* We (along with the other maintainers - if any exist), can start a conversation about how you can help the project.

or 

* Fork the resource repository
* Create your feature branch (`git checkout -b my-new-feature`)
* Commit your changes (`git commit -am 'Add some feature'`)
* Push to the branch (`git push origin my-new-feature`)
* Create new Pull Request

## What is still here?
So far, the DSC Tooling.  We'll probably break that out as well.  The focus of the repository will be documentation, examples and filing of issues that are broader than any one resource or tool.

Current Repositories
* [SystemHosting](https://github.com/PowerShellOrg/SystemHosting)
  * SHT_AllowedServices
  * SHT_DNSClient
  * SHT_GroupResource
  * SHT_IscsiInitiatorTargetPortal
  * SHT_MPIOSetting
  * SHT_NetAdapter
  * SHT_NetAdapterAdvancedProperty
  * SHT_NetAdapterBinding
  * SHT_NetAdapterNetBios
* [cWebAdministration](https://github.com/PowerShellOrg/cWebAdministration)
  * PSHOrg_cAppPool
  * PSHOrg_cWebsite
* [cChoco](https://github.com/PowerShellOrg/cChoco)
  * cChocoInstaller
  * cChocoPackageInstall
* [StackExchangeResources](https://github.com/PowerShellOrg/StackExchangeResources)
  * StackExchange_CertificateStore
  * StackExchange_FirewallRule
  * StackExchange_NetworkAdapter
  * StackExchange_Pagefile
  * StackExchange_PowerPlan
  * StackExchange_ScheduledTask
  * StackExchange_SetExecutionPolicy
  * StackExchange_Timezone
* [rchaganti](https://github.com/PowerShellOrg/rchaganti)
  * HostsFile
* [PowerShellAccessControl](https://github.com/PowerShellOrg/PowerShellAccessControl)
  * PowerShellAccessControl_cAccessControlEntry
  * PowerShellAccessControl_cSecurityDescriptor
  * PowerShellAccessControl_cSecurityDescriptorSddl
* [cSystemCenterManagement](https://github.com/PowerShellOrg/cSystemCenterManagement)
  * ICG_SCOMAgentMgmtGroup
  * ICG_SCOMBulkMP
  * ICG_SCOMImportMP
* [cSqlPs](https://github.com/PowerShellOrg/cSqlPs)
  * PSHOrg_cSqlHAEndPoint
  * PSHOrg_cSqlHAGroup
  * PSHOrg_cSqlHAService
  * PSHOrg_cSqlServerInstall
  * PSHOrg_cWaitForSqlHAGroup
  * cScriptResource
* [cSmbShare](https://github.com/PowerShellOrg/cSmbShare)
  * PSHOrg_cSmbShare
* [cRDPEnabled](https://github.com/PowerShellOrg/cRDPEnabled)
  * PSHOrg_cRDPEnabled
* [Craig-Martin](https://github.com/PowerShellOrg/Craig-Martin)
  * GlobalAssemblyCache 
* [cPSGet](https://github.com/PowerShellOrg/cPSGet)
  * PSHOrg_cPSGet
* [cPSDesiredStateConfiguration](https://github.com/PowerShellOrg/cPSDesiredStateConfiguration)
  * PSHOrg_cDSCWebService
* [cNetworking](https://github.com/PowerShellOrg/cNetworking)
  * PSHOrg_cDNSServerAddress
  * PSHOrg_cFirewall
  * PSHOrg_cIPAddress
* [cHyper-V](https://github.com/PowerShellOrg/cHyper-V)
  * PSHOrg_cVHD
  * PSHOrg_cVMHost
  * PSHOrg_cVMHyperV
  * PSHOrg_cVMSwitch
  * PSHOrg_cVhdFileDirectory
* [cFailoverCluster](https://github.com/PowerShellOrg/cFailoverCluster)
  * PSHOrg_cCluster
  * PSHOrg_cWaitForCluster
* [cComputerManagement](https://github.com/PowerShellOrg/cComputerManagement)
  * PSHOrg_cComputer
* [cActiveDirectory](https://github.com/PowerShellOrg/cActiveDirectory)
  * PSHOrg_cADDomain
  * PSHOrg_cADDomainController
  * PSHOrg_cADUser
  * PSHOrg_cWaitForADDomain
