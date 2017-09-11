$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
[xml]$config = Get-Content $PSScriptRoot\Configuration.xml 
$logdir = $config.Config.LogDirectory
$Script_Logfile = $config.Config.ScriptLogFilePath
$days = $config.Config.ScriptLogFilePath #this will result in n days of non-zipped log files
$archDir = $config.Config.ArchiveDirectory.'#text' #archive directory location
$archiveDays = $config.Config.NonArchiveZipDays #this will provide n days of zipped log files in the original directory - all others will be archived
[int]$disklimit = $config.Config.DiskLimit.'#text' 

function CheckDiskSpace($dir) {  
      
    $part = "DeviceID=`'$($dir.substring(0,2))`'"   
    $disk = Get-WmiObject Win32_LogicalDisk -Filter $part | Foreach-Object {$_.Size,$_.FreeSpace}  
      
    [int]$diskInGB = $disk[0]/1GB 
    Write-Host $diskInGB  
      
    if($diskInGB -lt $disklimit ) {  
        return $true  
    }else {  
        return $false  
    }  
}  
  
  
#checkDiskspace  
$checkDiskFlag = CheckDiskSpace($archDir)  
if($checkDiskFlag) {  
    #echo "low!!" 
      exit  
}  

$zipLogs = Get-ChildItem -Recurse -Path $logdir -Attributes !Directory -Filter *.zip  | Where-Object -FilterScript {

$_.LastWriteTime -lt (Get-Date).SubtractDays($archiveDays)

} #gets the zipped logs




foreach ($ziplog in $zipLogs)

{

    $origZipDir = $ziplog.DirectoryName             #gets the current folder name
    $fileName = $ziplog.Name                        #gets the current zipped log name
    $source = $origZipDir + '\' + $fileName         #builds the source data
    $destination = $archDir + '\' + $fileName       #builds the destination data

    Move-Item -Path $source -Destination $destination   #moves the file from the current location to the archive location

    $logtime = Get-Date
    $logtime.ToString() + ': Moved archive ' + $source + ' to ' + $destination | Out-File $Script_Logfile -Encoding UTF8 -Append #creates logfile entry

}