function ConvertTo-UserRightsAssignmentSummary {
    <#
    .SYNOPSIS
        Create a summary result of all user rights assignments.
    
    .DESCRIPTION
        Create a summary result of all user rights assignments.
        Provides a list with one entry per right per computer, grouping all assignees of that right.
    
    .PARAMETER InputObject
        The URA result objects as returned by Get-UserRightsAssignment
    
    .EXAMPLE
        PS C:\> Get-UserRightsAssignment | ConvertTo-UserRightsAssignmentSummary

        Generate a per-privilege report of the URA of the local computer.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $InputObject
    )

    begin {
        $inputList = [System.Collections.ArrayList]@()

        $selectProps = @(
            @{
                Name       = 'ComputerName'
                Expression = { $_.Group[0].ComputerName }
            }
            @{
                Name       = "Privilege"
                Expression = { $_.Group.Privilege | Sort-Object -Unique }
            }
            @{
                Name       = "Count"
                Expression = { @($_.Group.Member).Count }
            }
            @{
                Name       = "Member"
                Expression = { $_.Group.Member -join "," }
            }
            @{
                Name       = "Entries"
                Expression = { $_.Group }
            }
        )
    }
    process {
        $inputList.AddRange(@($InputObject))
    }
    end {
        $inputList | Group-Object ComputerName, Privilege | Select-PSFObject $selectProps -ShowProperty ComputerName, Privilege, Count, Member -TypeName 'UserRightsAssignment.Summary'
    }
}
