@{
    Nodes = 'FileServer01'

    BaseServerSettings = @{
        PowerPlan = 'Balanced'
    }

    FileServerSettings = @{
        Shares = @(
            @{
                Name = 'Websites$'
                Path = 'D:\Shares\Websites'
                FullAccess = @('BUILTIN\Administrators')
                ReadAccess = @('NT AUTHORITY\Authenticated Users')
            }
        )
    }
}

