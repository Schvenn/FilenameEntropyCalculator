@{RootModule = 'FilenameEntropyCalculator.psm1'
ModuleVersion = '1.0'
GUID = '183fff79-eb93-4865-8e07-14d7f4e4799f'
Author = 'Craig Plath'
CompanyName = 'Plath Consulting Incorporated'
Copyright = '© Craig Plath. All rights reserved.'
Description = 'This module recursively locates high entropy filenames within the specified path, providing output to screen, file or both. This is particularly useful for finding filenames written by malware.'
PowerShellVersion = '5.1'
FunctionsToExport = @('FilenameEntropyCalculator')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
FileList = @('FilenameEntropyCalculator.psm1')

PrivateData = @{PSData = @{Tags = @('antimalware', 'powershell', 'shannon entropy', 'entropy')
LicenseUri = 'https://github.com/Schvenn/FilenameEntropyCalculator/blob/main/LICENSE'
ProjectUri = 'https://github.com/Schvenn/FilenameEntropyCalculator'
ReleaseNotes = 'Initial release.'}}}
