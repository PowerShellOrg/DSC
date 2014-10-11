@{
    Nodes = 'WebServer01', 'WebServer02'

    BaseServerSettings = @{
        PowerPlan = 'Balanced'
    }

    WebServerSettings = @{
        Websites = @(
            @{
                Name = 'IntranetSite'
                LocalPath = 'C:\inetpub\wwwroot\Intranet'
                SourcePath = '\\FileServer01\Websites$\Intranet'
            }
        )
    }
}

