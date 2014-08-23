@{
    Nodes = 'WebServer01', 'WebServer02'
    Roles = 'WebServer', 'BaseServer'

    # PowerPlan is part of our sample configuration's "BaseServer" role.
    PowerPlan = 'Balanced'

    # Websites is part of our "WebServer" role.
    Websites = @(
        @{
            Name = 'IntranetSite'
            LocalPath = 'C:\inetpub\wwwroot\Intranet'
            SourcePath = '\\FileServer01\Websites$\Intranet'
        }
    )
}

