Dependencies for DSC Tooling modules
-------

Aside from your DSC resources and some inter-dependencies between modules in this Tooling folder, there are two external dependencies required to use these tools:

- The DscBuild module requires Pester v3.0.0 or later.  This can be obtained from Chocolatey, PSGet, PowerShellGet, NuGet, or directly from its [GitHub repo](https://github.com/pester/Pester).  This module is used to execute unit tests of your DSC resource modules before they are packaged up for the pull server.
- The DscConfiguration module requires ProtectedData v2.1 or later.  This can be obtained from PSGet, PowerShellGet, or from its [GitHub repo](https://github.com/dlwyatt/ProtectedData/releases/download/v2.1/ProtectedData.zip).  This module is used to encrypt and decrypt saved credentials in the DSC ConfigurationData folders, so passwords are not saved in plain text in source control.
