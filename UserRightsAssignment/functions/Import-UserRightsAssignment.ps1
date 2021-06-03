function Import-UserRightsAssignment {
    <#
    .SYNOPSIS
        Reads a GP Results XML file and processes any applicable UserRightsAssignments.
    
    .DESCRIPTION
        Reads a GP Results XML file and processes any applicable UserRightsAssignments.

        To generate such a file, use the following line on the system you want to generate the report:
        gpresult /F /SCOPE COMPUTER /X GPReport.xml
    
    .PARAMETER Path
        Path to the file(s) containing gp result XML files.
    
    .EXAMPLE
        PS C:\> Get-ChildItem *.xml | Import-UserRightsAssignment

        Reads the User Rights Assignment settings from all XML files in the current folder.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string[]]
        $Path
    )
    process {
        foreach ($pathItem in $Path) {
            try { [xml]$xml = Get-Content -Path $pathItem -ErrorAction Stop }
            catch {
                Write-PSFMessage -Level Error -Message "Error reading XML file: $pathItem" -ErrorRecord $_ -PSCmdlet $PSCmdlet -EnableException $true
                continue
            }

            $computerDomain = $xml.Rsop.ComputerResults.Domain
            $computerName = $xml.Rsop.ComputerResults.Name -replace '^.*?\\' -replace '\$$'
            
            $assignments = @($xml.Rsop.ComputerResults.ExtensionData).Where{
                $_.Name.'#text' -eq 'Security'
            }.Extension.UserRightsAssignment

            $gpoCache = @{ }

            foreach ($assignment in $assignments) {
                if (-not $gpoCache[$assignment.GPO.Identifier.'#text']) {
                    try { $gpoCache[$assignment.GPO.Identifier.'#text'] = Get-ADObject -LdapFilter "(&(objectClass=groupPolicyContainer)(name={$([guid]$assignment.GPO.Identifier.'#text')}))" -Properties DisplayName -Server $computerDomain -ErrorAction Ignore }
                    catch { } # Do nothing - if we can't resolve it, we can't resolve it.
                }
                
                foreach ($member in $assignment.Member) {
                    [PSCustomObject]@{
                        ComputerName   = $computerName
                        ComputerDomain = $computerDomain
                        ComputerFqdn   = "$($computerName).$($computerDomain)"
                        Privilege      = $assignment.Name
                        GPOId          = $assignment.GPO.Identifier.'#text'
                        GPOName        = $gpoCache[$assignment.GPO.Identifier.'#text'].DisplayName
                        Member         = $member.Name.'#text'
                        Identifier     = "$($assignment.Name)|$($member.Name.'#text')"
                    }
                }
            }
        }
    }
}
