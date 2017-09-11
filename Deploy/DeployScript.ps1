[xml]$deployinfo = Get-Content "C:\Users\ad949\Work Folders\Desktop\Deploy\DeployConfig.xml"
$list_webbox = $deployinfo.DeployConfig.Webboxes.Webbox
$source_code_path = $deployinfo.DeployConfig.sourcecodepath
$deployLog = $deployinfo.DeployConfig.DeployLogs

foreach($webbox in $list_webbox) {
    
    Write-Host "Initiating......" -ForegroundColor Yellow

        
    if(Test-Connection -Cn $webbox.Name -Quiet) {

        $webbox_name = $webbox.Name
        $full_path = $webbox.Destination.'#text' + "\" + $webbox.Destination.foldername

        #Create Archival Directory
        if(!(Test-Path -Path "\\$webbox_name\e$\archive")) {
            Invoke-Command -ComputerName $webbox_name -ScriptBlock { New-Item E:\archive -ItemType Directory }
            Write-Host "'archive' directory created." -ForegroundColor Green
        }


        if (Test-Path -Path "\\$webbox_name\$full_path")

        {

            Write-Host "\\$webbox_name\$full_path Already exists" -ForegroundColor Red
            continue

        }

        Try {
                $path = $webbox.Destination.'#text'
                Copy-Item $source_code_path -Destination \\$webbox_name\$path -Recurse

                $date = Get-Date
                Write-Host "$($date.ToString())  Item: $source_code_path copied to $webbox_name at location : $full_path" -ForegroundColor Green
                $date.ToString() + " Item: " + $source_code_path + " copied to " + $webbox_name + " at location : " + $full_path | Out-File -FilePath $deployLog -Encoding utf8 -Append
        }       
        Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            
            $date = Get-Date
            Write-Host "$($date.ToString()) $ErrorMessage $FailedItem"
            $date.ToString() + $ErrorMessage + $FailedItem | Out-File -FilePath $deployLog -Encoding utf8 -Append
        }
                   
     }else {
            $date = Get-Date
            Write-Host "$($date.ToString()) Not online: $webbox.Name" 
            $date.ToString() + " Not online: " +$webbox.Name | Out-File -FilePath $deployLog -Encoding utf8 -Append
     }
}



###Powershell Task Scheduler in Remote Nodes##


foreach($webbox in $list_webbox) {

    Invoke-Command -ComputerName $webbox.Name -ScriptBlock {
        
        $item_list = Get-ChildItem -Path "E:\LogManagementPackage" -Filter *.ps1
        foreach($item in $item_list) {
            $dir = $item.Directory.ToString()
            Unblock-File -Path "$dir\$($item.Name)" -Verbose
        }

        Function CreateScheduledTaskFolder ($TASKPATH)
        {
            $ERRORACTIONPREFERENCE = "stop"
            $SCHEDULE_OBJECT = New-Object -ComObject schedule.service
            $SCHEDULE_OBJECT.connect()
            $ROOT = $SCHEDULE_OBJECT.GetFolder("\")
            Try 
            {
                $null = $SCHEDULE_OBJECT.GetFolder($TASKPATH)
                Write-Host "$TASKPATH Already exists" -ForegroundColor Red
            }
            Catch { 
                $null = $ROOT.CreateFolder($TASKPATH)
                $logtime = Get-Date
                Write-Host "$($logtime.ToString())  Task Path Created: $TASKPATH" -ForegroundColor Green
                #$logtime.ToString() + " Task Path Created: " + $TASKPATH | Out-File -FilePath $deployLog -Encoding utf8 -Append      
            }
            Finally 
            { 
                $ERRORACTIONPREFERENCE = "continue" 
            }
 
        }

        Function CreateScheduledTask ($TASKNAME, $TASKPATH, $TASKDESCRIPTION, $SCRIPT)
        {
            $ACTION = New-ScheduledTaskAction -Execute "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-File $SCRIPT"
            $TRIGGER =  New-ScheduledTaskTrigger -Daily -At 4:30am
            Register-ScheduledTask -Action $ACTION -Trigger $TRIGGER -TaskName $TASKNAME -Description "$TASKDESCRIPTION" -TaskPath $TASKPATH -User "PARTNERS\PRTEXP" -Password ")(14jBvKfb7KStqxJ"  -RunLevel Highest

            $logtime = Get-Date
            Write-Host "$($logtime.ToString()) Created Scehduled Task: $TASKNAME" -ForegroundColor Green
            #$logtime.ToString() + " Created Scehduled Task: " + $TASKNAME | Out-File -FilePath $deployLog -Encoding utf8 -Append
        }

        Function ConfigureScheduledTaskSettings ($TASKNAME, $TASKPATH)
        {
            $SETTINGS = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Hidden -RestartCount 3
            Set-ScheduledTask -TaskName $TASKNAME -Settings $SETTINGS -TaskPath $TASKPATH

            $logtime = Get-Date
            Write-Host "$($logtime.ToString()) Configured Scehduled Task settings: $TASKNAME"
            #$logtime.ToString() + " Configured Scehduled Task settings: " + $TASKNAME | Out-File -FilePath $deployLog -Encoding utf8 -Append
        }

        #Schedule task path
        $scheduleTaskPath = "LogManagement"
        CreateScheduledTaskFolder $scheduleTaskName $scheduleTaskPath

        ###############Zipping Logs###########################

        #Schedule task name
        $scheduleTaskName = "ZippingLogs"
    
        #Script to schedule
        $Script = "E:\LogManagementPackage\CompressLogs.ps1" 

        CreateScheduledTask $scheduleTaskName $scheduleTaskPath "Zipping Log Files---Refer. Configuration.xml for details" $Script | Out-Null
        ConfigureScheduledTaskSettings $scheduleTaskName $scheduleTaskPath | Out-Null

    
    
        ##############Archiving Zipped Logs####################
        #Schedule task name
        $scheduleTaskName = "ArchivedZippedLogs"

        #Script to schedule
        $Script = "E:\LogManagementPackage\ziplogarchive.ps1" 

        CreateScheduledTask $scheduleTaskName $scheduleTaskPath "Moving old zipped files to archive---Refer. Configuration.xml for details" $Script | Out-Null
        ConfigureScheduledTaskSettings $scheduleTaskName $scheduleTaskPath | Out-Null


    
        ##############Removing Old Archived Zips################
        #Schedule task name
        $scheduleTaskName = "RemoveOldArchivedZippedLogs"
        
        #Script to schedule
        $Script = "E:\LogManagementPackage\RemoveOldArchivedLogs.ps1" 
        
        CreateScheduledTask $scheduleTaskName $scheduleTaskPath "Removes old archived and zipped files permanently---Refer. Configuration.xml for details" $Script | Out-Null
        ConfigureScheduledTaskSettings $scheduleTaskName $scheduleTaskPath | Out-Null

    }#end of invoke-command scriptblock
}
