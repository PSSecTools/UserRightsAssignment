function Compare-UserRightsAssignment {
    <#
    .SYNOPSIS
        Compare two sets of User Rights Assignments and generate the diff.
    
    .DESCRIPTION
        Compare two sets of User Rights Assignments and generate the diff.
    
    .PARAMETER Assignment
        One set of assignments to compare.
        Provide a list of objects as returned by Get-UserRightsAssignment.
    
    .PARAMETER DiffAssignment
        The other set of assignments to compare.
        Provide a list of objects as returned by Get-UserRightsAssignment.
    
    .EXAMPLE
        PS C:\> Compare-UserRightsAssignment -Assignment $server1 -DiffAssignment $server2

        Generate the delta between the two datasets stored in $server1 and $sever2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $Assignment,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $DiffAssignment
    )

    process {
        $groups = @($Assignment) + @($DiffAssignment) | Group-Object Identifier
        $results = foreach ($group in $groups | Where-Object Count -LT 2) {
            if ($group.Group[0] -in $Assignment) {
                [PSCustomObject]@{
                    ComputerName = $group.Group[0].ComputerName
                    Privilege    = $group.Group[0].Privilege
                    Member       = $group.Group[0].Member
                    Direction    = '=>'
                    Object       = $group.Group[0]
                }
            }
            else {
                [PSCustomObject]@{
                    ComputerName = $group.Group[0].ComputerName
                    Privilege    = $group.Group[0].Privilege
                    Member       = $group.Group[0].Member
                    Direction    = '<='
                    Object       = $group.Group[0]
                }
            }
        }
        $results | Select-PSFObject -KeepInputObject -TypeName 'UserRightsAssignment.Diff' -ShowProperty ComputerName, Direction, Privilege, Member
    }
}
