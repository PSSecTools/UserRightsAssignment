function Get-UserRightsAssignment {
    <#
    .SYNOPSIS
        Execute gpresult on the target computer and get a list of effective user rights assignments.
    
    .DESCRIPTION
        Execute gpresult on the target computer and get a list of effective user rights assignments.
        Uses WinRM for remote access.
    
    .PARAMETER ComputerName
        The computer(s) to scan.
        Servers will be processed in parallel if explicitly bound, sequential if piped.
        Defaults to localohost.
    
    .PARAMETER Credential
        The credentials to use for connecting to the remote host.

	.PARAMETER EnableException
		This parameters disables user-friendly warnings and enables the throwing of exceptions.
		This is less user friendly, but allows catching exceptions in calling scripts.
    
    .EXAMPLE
        PS C:\> Get-UserRightsAssignment
        
        Get the URA of the local host.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [PSFComputer[]]
        $ComputerName = $env:COMPUTERNAME,

        [PSCredential]
        $Credential,

        [switch]
        $EnableException
    )

    begin {
        $scriptblock = {
            #region Functions
            function Invoke-SystemCommand {
                <#
                .SYNOPSIS
                    Execute a scriptblock as SYSTEM by setting up a temporary scheduled task.
                
                .DESCRIPTION
                    Execute a scriptblock as SYSTEM by setting up a temporary scheduled task.
                
                .PARAMETER Name
                    The name of the task
                
                .PARAMETER Scriptblock
                    The code to run
                
                .PARAMETER Mode
                    Whether to run it right away (instant) or after the next reboot (OnBoot).
                    Default: Instant
            
                .PARAMETER Wait
                    Wait for the task to complete.
                    Only applicable in "Instant" mode.
            
                .PARAMETER Timeout
                    Timeout how long we are willing to wait for the task to complete.
                    Only applicable in combination with "-Wait"
                
                .EXAMPLE
                    PS C:\> Invoke-SystemCommand -Name 'WhoAmI' -ScriptBlock { whoami | Set-Content C:\temp\whoami.txt }
            
                    Executes the scriptblock as system
                #>
                [CmdletBinding()]
                Param (
                    [Parameter(Mandatory = $true)]
                    [string]
                    $Name,
            
                    [Parameter(Mandatory = $true)]
                    [string]
                    $Scriptblock,
            
                    [ValidateSet('Instant', 'OnBoot')]
                    [string]
                    $Mode = 'Instant',
            
                    [switch]
                    $Wait,
            
                    [timespan]
                    $Timeout = '00:00:30'
                )
                
                process {
                    if ($Mode -eq 'OnBoot') { $Scriptblock = "Unregister-ScheduledTask -TaskName 'PowerShell_System_$Name' -Confirm:`$false", $Scriptblock -join "`n`n" }
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Scriptblock)
                    $encodedCommand = [Convert]::ToBase64String($bytes)
            
                    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -EncodedCommand $encodedCommand"
                    $principal = New-ScheduledTaskPrincipal -UserId SYSTEM -RunLevel Highest -LogonType Password
                    switch ($Mode) {
                        'Instant' { $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) }
                        'OnBoot' { $trigger = New-ScheduledTaskTrigger -AtStartup }
                    }
                    $task = Register-ScheduledTask -TaskName "PowerShell_System_$Name" -Description "PowerShell Task - $Name" -Action $action -Trigger $trigger -Principal $principal
                    if ($Mode -eq 'Instant') {
                        $task | Start-ScheduledTask
                        if (-not $Wait) {
                            Start-Sleep -Seconds 1
                        }
                        else {
                            $limit = (Get-Date).Add($Timeout)
                            while (($task | Get-ScheduledTask).State -ne "Ready") {
                                if ($limit -lt (Get-Date)) {
                                    $task | Unregister-ScheduledTask -Confirm:$false
                                    throw "Task execution exceeded time limit ($Timeout)"
                                }
                            }
                        }
                        $task | Unregister-ScheduledTask -Confirm:$false
                    }
                }
            }
            #endregion Function
            $csDomain = (Get-ComputerInfo -Property CsDomain).CsDomain
            
            $result = [PSCustomObject]@{
                ComputerName   = $ENV:COMPUTERNAME
                ComputerDomain = $csDomain
                ComputerFqdn   = "$($ENV:COMPUTERNAME).$($csDomain)"
                Success        = $false
                Results        = @()
                Message        = [System.Collections.ArrayList]::new()
            }
            try {
                Invoke-SystemCommand -Name 'GPReport' -ScriptBlock {
                    gpresult /F /SCOPE COMPUTER /X C:\GPReport.xml
                } -Wait
            }
            catch {
                $null = $result.Message.Add("$_")
                Write-Warning "[$($ENV:COMPUTERNAME).$($csDomain)] $_"
            }

            if (-not (Test-Path 'C:\GPReport.xml')) {
                $null = $result.Message.Add("GPReport.xml not found")
                return $result
            }

            try { [xml]$xml = Get-Content C:\GPReport.xml -ErrorAction Stop }
            catch {
                Write-Warning "[$($ENV:COMPUTERNAME).$($csDomain)] Error Reading temporary GP Report File: $_"
                Remove-Item -Path C:\GPReport.xml -Force -ErrorAction Ignore
                $null = $result.Message.Add("Error Reading temporary GP Report File: $_")
                return $result
            }
            Remove-Item -Path C:\GPReport.xml -Force -ErrorAction Ignore
            

            $assignments = @($xml.Rsop.ComputerResults.ExtensionData).Where{
                $_.Name.'#text' -eq 'Security'
            }.Extension.UserRightsAssignment

            $gpoCache = @{ }

            $result.Results = foreach ($assignment in $assignments) {
                if (-not $gpoCache[$assignment.GPO.Identifier.'#text']) {
                    $gpoCache[$assignment.GPO.Identifier.'#text'] = Get-GPO -Guid $assignment.GPO.Identifier.'#text' -Server localhost
                }
                
                foreach ($member in $assignment.Member) {
                    [PSCustomObject]@{
                        ComputerName   = $ENV:COMPUTERNAME
                        ComputerDomain = $csDomain
                        ComputerFqdn   = "$($ENV:COMPUTERNAME).$($csDomain)"
                        Privilege      = $assignment.Name
                        GPOId          = $assignment.GPO.Identifier.'#text'
                        GPOName        = $gpoCache[$assignment.GPO.Identifier.'#text'].DisplayName
                        Member         = $member.Name.'#text'
                        Identifier     = "$($assignment.Name)|$($member.Name.'#text')"
                    }
                }
            }
            $result.Success = $true
            $result
        }
    }
    process {
        $failed = $null
        $results = Invoke-PSFCommand -ComputerName $ComputerName -Credential $Credential -ScriptBlock $scriptblock -ErrorVariable failed -ErrorAction SilentlyContinue
        $failedProcessed = $failed | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] } | Group-Object {
            $_.Exception.Message
        } | ForEach-Object { $_.Group[0] }
        foreach ($errorItem in $failedProcessed) {
            Write-PSFMessage -Level Warning -Message "[$($errorItem.TargetObject.OriginalConnectionInfo.ComputerName)]" -ErrorRecord $errorItem -Tag error, WinRM -PSCmdlet $PSCmdlet -EnableException $EnableException.ToBool() -Target $errorItem.TargetObject.OriginalConnectionInfo.ComputerName
        }
        $resultData = foreach ($result in $results) {
            if ($result.Success) {
                $result.Results
                continue
            }

            Write-PSFMessage -Level Warning -Message "[$($result.ComputerFqdn)] Error gathering data:`n`t{0}" -StringValues ($result.Message -join "`n`t") -Target $result.ComputerFqdn -Tag error, processing -PSCmdlet $PSCmdlet -EnableException $EnableException.ToBool()
        }
        # Store and return values, in order to avoid mixing output with warnings
        $resultData
    }
}
