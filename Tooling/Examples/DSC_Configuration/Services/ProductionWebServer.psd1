@{
    Nodes = 'WebServer02'
    Roles = 'WebServer', 'BaseServer'

    BaseServerSettings = @{
        PowerPlan = 'High Performance'
    }

    WebServerSettings = @{
        Websites = @(
            @{
                Name = 'ExternalSite01'
                LocalPath = 'C:\inetpub\wwwroot\ExternalSite01'
                SourcePath = '\\FileServer01\Websites$\ExternalSite01'
            }

            @{
                Name = 'ExternalSite02'
                LocalPath = 'C:\inetpub\wwwroot\ExternalSite02'
                SourcePath = '\\FileServer01\Websites$\ExternalSite02'
            }
        )
    }
}

