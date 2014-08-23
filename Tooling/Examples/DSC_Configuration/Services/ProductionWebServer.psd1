@{
    Nodes = 'WebServer02'
    Roles = 'WebServer', 'BaseServer'

    # PowerPlan is part of our sample configuration's "BaseServer" role.
    PowerPlan = 'High Performance'

    # Websites is part of our "WebServer" role.
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

