$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
[xml]$config = Get-Content $PSScriptRoot\Configuration.xml 
$logdir = $config.Config.LogDirectory
$Script_Logfile = $config.Config.ScriptLogFilePath
$days = $config.Config.UnzipDays 
$logs = Get-ChildItem -Recurse -Path $logdir -Attributes !Directory -Filter *.log | Where-Object -FilterScript { $_.LastWriteTime.AddDays($days) -lt (Get-Date) } #gets the zipped logs

foreach ($log in $logs)

{

    $name = $log.name #gets the filename
    $directory = $log.DirectoryName #gets the directory name
    $LastWriteTime = $log.LastWriteTime #gets the lastwritetime of the file
    $zipfile = $name.Replace('.log','.zip') #creates the zipped filename
    $source = $directory + "\" + $name
    $destination = $directory + "\" + $zipfile  
    
    try{
        Compress-Archive -LiteralPath $source -DestinationPath $destination
        
        Remove-Item -Path $directory\$name #deletes the original log file
        
        $logtime = Get-Date
        $logtime.ToString() + ': Created zip ' + $directory + '\' + $zipfile + '. Deleted original logfile: ' + $name | Out-File $Script_Logfile -Encoding UTF8 -Append #writes logfile entry

    }catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
            
        $date = Get-Date
        $date.ToString() + $ErrorMessage + $FailedItem
        $date.ToString() + $ErrorMessage + $FailedItem | Out-File -FilePath $Script_Logfile -Encoding utf8 -Append
    }
    
    

}




