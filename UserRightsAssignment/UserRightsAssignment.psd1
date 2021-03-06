@{
    # Script module or binary module file associated with this manifest
    RootModule        = 'UserRightsAssignment.psm1'
	
    # Version number of this module.
    ModuleVersion     = '1.0.0'
	
    # ID used to uniquely identify this module
    GUID              = 'fec5ae4c-98d2-40f2-9211-9d8221ea0ea4'
	
    # Author of this module
    Author            = 'Friedrich Weinmann'
	
    # Company or vendor of this module
    CompanyName       = ' '
	
    # Copyright statement for this module
    Copyright         = 'Copyright (c) 2021 Friedrich Weinmann'
	
    # Description of the functionality provided by this module
    Description       = 'Analyze the effective User Rights Assignments on a computer and compare results'
	
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
	
    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules   = @(
        @{ ModuleName = 'PSFramework'; ModuleVersion = '1.6.201' }
    )
	
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @('bin\UserRightsAssignment.dll')
	
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @('xml\UserRightsAssignment.Types.ps1xml')
	
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @('xml\UserRightsAssignment.Format.ps1xml')
	
    # Functions to export from this module
    FunctionsToExport = @(
        'Compare-UserRightsAssignment'
        'ConvertTo-UserRightsAssignmentSummary'
        'Get-DomainUserRightsAssignment'
        'Get-UserRightsAssignment'
        'Import-UserRightsAssignment'
    )
	
    # List of all modules packaged with this module
    ModuleList        = @()
	
    # List of all files packaged with this module
    FileList          = @()
	
    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
		
        #Support for PowerShellGet galleries.
        PSData = @{
			
            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()
			
            # A URL to the license for this module.
            # LicenseUri = ''
			
            # A URL to the main website for this project.
            # ProjectUri = ''
			
            # A URL to an icon representing this module.
            # IconUri = ''
			
            # ReleaseNotes of this module
            # ReleaseNotes = ''
			
        } # End of PSData hashtable
		
    } # End of PrivateData hashtable
}