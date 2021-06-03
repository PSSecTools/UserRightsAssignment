# User Rights Assignment

## Synopsis

This PowerShell module is designed to ...

+ analyze the effective user rights assignments on any given computer.
+ provide insights into where the curent URA settings come from
+ compare the URA between multiple result sets to detect the delta between two computer

## Installation

To install this module, run the following command on an internet facing computer:

```powershell
Install-Module UserRightsAssignment -Scope CurrentUser
```

To transport this module to a non-internet facing machine, download the module and its dependencies to a target folder:

```powershell
# Download into the current folder
Save-Module UserRightsAssignment -Path .
```

then copy them to the machine from which you want to execute the commands.
The module and its dependencies should be copied into a folder on the target machine where PowerShell knows to look for modules.
To get a list of these paths, run the following line in the PowerShell console on the target machine:

```powershell
$env:PSModulePath -split ";"
```

Any of these paths should do.

## Prerequisites

This module depends on two modules:

+ PSFramework
+ ActiveDirectory

The former is added as an explicit module dependency and downloaded together with this module.
The ActiveDirectory module needs to be installed via Windows tools, either as a Server Feature (on Windows Servers) or a Windows Optional Feature (on Windows 10 Clients).

Windows PowerShell 5.1 or later (including any PowerShell Core versions) is also required.

## Using it

To get a simple list of assignments, run this command:

```powershell
Get-UserRightsAssignment -ComputerName server1,server2
```

To compare two different computers, do this:

```powershell
$server1 = Get-UserRightsAssignment -ComputerName server1
$server2 = Get-UserRightsAssignment -ComputerName server2
Compare-UserRightsAssignment -Assignment $server1 -DiffAssignment $server2
```
