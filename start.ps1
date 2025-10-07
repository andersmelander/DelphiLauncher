$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 5) {
  throw "PowerShell version 5 or better required. Version $($PSVersionTable.PSVersion.Major) found."
}

try {
  Install-Module -Name PsIni -Scope CurrentUser -AllowClobber -Confirm:$False
} catch [System.Exception] {
  # Assume TLS is the problem
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  # Just retry
  Install-Module -Name PsIni -Scope CurrentUser -AllowClobber -Confirm:$False
}

$ENV_ROOT = $PSScriptRoot

if (-not(Test-Path "$ENV_ROOT\environment.ini")) {
  throw 'environment.ini missing'
}

$ini = Get-IniContent $("$ENV_ROOT\environment.ini")

if (-not($ini.Contains('environment'))) {
  throw '[environment] section missing from environment.ini'
}

$RootKey = $ini['environment']['rootkey'] # 'DelphiLauncher'
if ([String]::IsNullOrWhiteSpace($RootKey)) {
  $RootKey = 'DelphiLauncher'
}
$Project = $ini['environment']['project'] # 'FooBar 5.13'
$Revision = $ini['environment']['revision'] # '1'
$Version = $ini['environment']['delphi'] # '20.0'

$Source = $("HKCU:\Software\Embarcadero\BDS\$Version")
$Session = $("HKCU:\Software\Embarcadero\$RootKey\$Version")

$CurrentRevision = (Get-ItemProperty -ErrorAction SilentlyContinue -Path $Session -Name 'Revision').Revision

# Unique list of package folders - used later
$PackageFolders = @{}

# User might have deleted packages folder in order to save space. In that case we ignore the stored revision.
if (($CurrentRevision -ne "$Project - $Revision") -or (-not (Test-Path "$ENV_ROOT\packages"))) {


# Delete existing session registry tree
if (Test-Path $Session) {
  Remove-Item -Path $Session -Recurse -Force
}

# Copy existing Delphi registry tree into session tree
New-Item -Path $Session -Force
#Copy-Item can't be used due to bug
#Copy-Item -Path $("Registry::$Source") -Destination $("Registry::$Session") -Recurse
reg.exe copy "$($Source.Replace(':', ''))" "$($Session.Replace(':', ''))" /s /f

# Remove all "Known Packages" keys except those that contains "$(BDSBIN)" from session tree
$KnownPackages = Get-ItemProperty $("$Session\\Known Packages")
$KnownPackages.PSObject.Properties | ForEach-Object {
  if (($_.Name -notmatch '\$\(BDSBIN\)') -and ($_.Name -notmatch '^PS.+'))  {
    $Name = $_.Name
    Remove-ItemProperty -Path $("$Session\\Known Packages") -Name $Name -Force
  }
}

# Extract packages.zip if it exists
if (Test-Path "$ENV_ROOT\packages.zip") {
  "Extracting packages from zip..."

  # Delete existing package files
  if (Test-Path "$ENV_ROOT\packages") {
    "Removing existing packages..."
    Remove-Item -Recurse -Force "$ENV_ROOT\packages";
  }

  # Unzip backup file
  $Shell = New-Object -ComObject shell.application
  $Zip = $Shell.NameSpace("$ENV_ROOT\packages.zip")

  foreach ($ZipItem in $Zip.items()) {
    # Unzip file
    # 1552 =
    #   16:   "Yes to all"
    #   512:  Do not confirm the creation of a new directory if the operation requires one to be created.
    #   1024: Do not display a user interface if an error occurs.
    "Extracting: $($ZipItem.name)"
    $Shell.Namespace($ENV_ROOT).CopyHere($ZipItem, 1552);
  }
}

# Read list of design time packages
if (-not(Test-Path "$ENV_ROOT\packages.txt")) {
  throw 'packages.txt missing'
}
$hashtables = (Get-Content "$ENV_ROOT\packages.txt") -replace '"(.*)"=(.*)','$1=$2' -replace '\\','\'| ConvertFrom-StringData

$Packages = @{}
#<#
foreach ($hashtable in $hashtables) {
#foreach ($Package in $hashtables) {
  foreach ($Package in $hashtable.GetEnumerator()) {
    if ($Package.key -notmatch '\$\(BDSBIN\)') {
      $Name = Split-Path -Path $($package.key) -Leaf
      $Packages.Add($($Name.ToLower()), $package.value)
#      New-ItemProperty -Path $("$Session\Known Packages") -Name $($package.key) -Value $($package.value) -PropertyType String -Force
    }
  }
}
#>

# Add packages on disk to "Known Packages" in session tree
if (-not(Test-Path "$ENV_ROOT\Packages")) {
  throw 'Packages sub-folder missing'
}
$Files = Get-ChildItem -Path "$ENV_ROOT\Packages" -Recurse -Filter '*.bpl'
foreach ($File in $Files) {
  $Filename = $File.Name.ToLower()
  if ($Packages.ContainsKey($Filename)) {
    New-ItemProperty -Path $("$Session\Known Packages") -Name $($File.FullName) -Value $($Packages[$Filename]) -PropertyType String -Force

    $Key = $File.DirectoryName.ToLower()
    if ($PackageFolders.ContainsKey($Key) -eq $False) {
      $PackageFolders.Add($Key, $File.DirectoryName);
    }
  } else {
    "Package file not registered: $Filename"
  }
}

# Store Revision so we can skip the setup next time
New-ItemProperty -Path $Session -Name 'Revision' -Value "$Project - $Revision" -PropertyType String -Force

# Alter the IDE caption so we can see that we're running with a custom config
$Personality = (Get-ItemProperty -ErrorAction SilentlyContinue -Path $("$Session\Personalities") -Name 'Delphi.Win32').'Delphi.Win32'
$Personality = $("$Personality (Customized for $Project)")
New-ItemProperty -Path $("$Session\Personalities") -Name 'Delphi.Win32' -Value $Personality -PropertyType String -Force

} else {
  $Files = Get-ChildItem -Path "$ENV_ROOT\Packages" -Recurse -Filter '*.bpl'
  foreach ($File in $Files) {
    $Key = $File.DirectoryName.ToLower()
    if ($PackageFolders.ContainsKey($Key) -eq $False) {
      $PackageFolders.Add($Key, $File.DirectoryName);
    }
  }
}

# Add package folders to path so packages can be found if one package depends on another
foreach ($Folder in $PackageFolders.Values) {
  $env:Path = "$Folder;$env:Path"
}


# Launch Delphi, using the session tree
$BDS = Get-ItemProperty -Path $Session
& $($BDS.App) "-r$RootKey"
