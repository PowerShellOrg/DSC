function Test-NodeHasRole
{
    param (
        [Parameter(Mandatory)]
        [hashtable] $Node,

        [Parameter(Mandatory)]
        [string] $Role
    )

    return $Node.Roles -is [hashtable] -and $Node.Roles.ContainsKey($Role)
}
