$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
[xml]$config = Get-Content $PSScriptRoot\Configuration.xml 
$archiveDir = $config.Config.ArchiveDirectory.'#text'
$removeArchiveDays = $config.Config.ArchiveZipDays
$logfile = $config.Config.ScriptLogFilePath

#List of files to be deleted
$filelist = Get-ChildItem -Recurse -Path $archiveDir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {
            $_.LastWriteTime.AddDays($removeArchiveDays) -lt (Get-Date) }
#echo "hello"

foreach($file in $filelist) {
    Remove-Item $file.FullName -Recurse
    $logtime.ToString() + 'Removed Archived File: ' + $file.FullName| Out-File $logfile -Encoding UTF8 -Append #creates logfile entry
}
