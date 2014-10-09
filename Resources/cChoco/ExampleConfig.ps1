Configuration myChocoConfig
{
   Import-DscResource -Module cChoco  
   Import-DscResource -Module cGit  
   Node "localhost"
   {
      LocalConfigurationManager
      {
          ConfigurationMode = "ApplyAndAutoCorrect"
          ConfigurationModeFrequencyMins = 30 #must be a multiple of the RefreshFrequency and how often configuration is checked
      }
      cChocoInstaller installChoco
      {
        InstallDir = "c:\choco"
      }
      cChocoPackageInstaller installGit
      {
        Name = "git.install"
        DependsOn = "[cChocoInstaller]installChoco"
      }
      cGitPull pullRepo
      {
        Name = 'test'
        RepositoryLocal = "c:\temp\gitdsc\"
        RepositoryRemote = 'https://github.com/lawrencegripper/FluentMongoIntegrationTesting'
        LocationOfGitExe = "C:\Program Files (x86)\Git\bin\git.exe"
        DependsOn = "[cChocoPackageInstaller]installGit"
      }
      
   }
} 

myChocoConfig

Start-DscConfiguration .\myChocoConfig -wait -Verbose