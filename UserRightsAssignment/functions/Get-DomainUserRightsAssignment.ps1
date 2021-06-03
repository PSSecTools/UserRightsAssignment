function Get-DomainUserRightsAssignment {
    <#
    .SYNOPSIS
        Scan all DCs of a domain for User Rights Assignments.
    
    .DESCRIPTION
        Scan all DCs of a domain for User Rights Assignments.
    
    .PARAMETER Server
        The domain(s) to scan.
    
    .PARAMETER Credential
        The credentials to use.
    
    .EXAMPLE
        PS C:\> Get-DomainUserRightsAssignment

        Scan the current user's domain,

    .EXAMPLE
        PS C:\> Get-DomainUserRightsAssignment -Server contoso.com

        Scan all DCs in the domain contoso.com
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSFComputer[]]
        $Server = $env:USERDNSDOMAIN,

        [PSCredential]
        $Credential
    )

    begin {
        $parameters = $PSBoundParameters | ConvertTo-PSFHashtable -Include Credential
    }
    process {
        foreach ($serverName in $Server) {
            $parameters.Server = $serverName
            $domain = Get-ADDomain @parameters
            $domainControllers = Get-ADDomainController @parameters -Filter *
            $results = Get-UserRightsAssignment -ComputerName $domainControllers.HostName

            $resultHash = @{ }
            foreach ($group in $results | Group-Object ComputerName) {
                $resultHash[$group.Name] = $group.Group
            }

            [PSCustomObject]@{
                PSTypeName     = 'UserRightsAssignment.DomainInfo'
                Domain         = $domain.DnsRoot
                DomainObject   = $domain
                Entries        = $results
                PoliciesInSync = -not ($results | Group-Object Identifier | Where-Object Count -LT @($domainControllers).Count)
                Summary        = $results | ConvertTo-UserRightsAssignmentSummary
                ByDC           = $resultHash
            }
        }
    }
}
