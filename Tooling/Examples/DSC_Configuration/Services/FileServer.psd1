@{
    Nodes = 'FileServer01'
    Roles = 'FileServer', 'BaseServer'

    # PowerPlan is part of our sample configuration's "BaseServer" role.
    PowerPlan = 'Balanced'

    # Shares is part of our "FileServer" role
    Shares = @(
        @{
            Name = 'Websites$'
            Path = 'D:\Shares\Websites'
            FullAccess = @('BUILTIN\Administrators')
            ReadAccess = @('NT AUTHORITY\Authenticated Users')
        }
    )
}

