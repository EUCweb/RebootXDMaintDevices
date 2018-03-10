<#

.SYNOPSIS
Reboot XD Devices there have Maintenance Mode enabled

.DESCRIPTION
Maintennace Mode ON does not rebooting the VDA's, this script will do that and send
a message to the user if someone is logged in

.EXAMPLE


.NOTES
Author: Matthias Schlimm
      	Company: EUCweb.com
		
		History

Last Change: 22.08.2017 MS: Script created
Last Change:

.LINK


#>

Begin {
	clear-host
    $script_path = $MyInvocation.MyCommand.Path
	$script_dir = Split-Path -Parent $script_path
    $timestamp = Get-Date -Format yyyyMMdd-HHmmss
    $computer = $Env:COMPUTERNAME
    $cu = $env:username
    $Global:SumData=@()
    $LogFolder = "Logs"
    $Global:LogFilePath = "$script_dir\$LogFolder"
    $Global:LogFileName = "Invoke-RebootXDMaintDevices_$timestamp.log"
    $Global:LOGFile="$LogFilePath\$LogFileName"
    $Global:Domain = (Get-WmiObject -Class Win32_ComputerSystem).domain
    $ModulePath = "$script_dir"
    


##### ---- Start custom specified entries ---- ####
	
	$XDBrokers = @("Broker1inSite1","Broker1inSite2")
    [int]$Wait1 = 1800   #wait time in seconds before reboot

    $RebootCycle = "10"  #how many machines rebooted in one Reboot Cycle
    [int]$Wait2 = 300   #wait time in seconds between rebootCycles 

##### ---- End custom specified entries ---- ####




#load Modules
    try {
        $Modules = @(Get-ChildItem -path $ModulePath -filter "*.psm1" -Force -Recurse)
        ForEach ($module in $Modules) {
            
            Write-Host " --- --- Importing Module $module PSM1--- --- " -ForegroundColor Green -BackgroundColor DarkGray
            Import-Module -Name "$ModulePath\$module" -Force
        }
    }
    catch {
        Throw "An error occured while loading modules. The error is: $_"
        Exit 1
    }

	
	
	###------------------------------------------------
}


Process {
    Set-LogFilePath -LFP $LogFilePath
    Write-Log -Msg "Checking Prerequisites" -ShowConsole -Color Cyan
    Write-Log -Msg "Logfile would be set to $LOGFile" -ShowConsole -Color DarkCyan -SubMsg
    Invoke-LogRotate -Versions 5 -Directory $LogFilePath	
    $WaitInMinutes = $Wait1 / 60
    
    Add-PSSnapin Citrix*
    ForEach ($XDBroker in $XDBrokers)
    {
        Write-Log -Msg "Processing XenDesktop Broker $XDBroker" -ShowConsole Cyan
        $MaintDevices = Get-BrokerMachine -AdminAddress "$XDBroker" | Where-Object {$_.InMaintenanceMode -eq $true} | % {$_.DNSName}
        
        ForEach ($MaintDevice in $MaintDevices)
        {
            Write-Log -Msg "Processing Maintenance Devices $MaintDevice on XDBroker $XDBroker" -ShowConsole Cyan
            
            # Processing HDX Session
            $HDXsessions = Get-BrokerSession -DNSName "$($MaintDevice)" -Protocol "HDX"| % {$_.Uid}
            IF (!($HDXsessions -eq $null))
            {
                ForEach ($HDXsession in $HDXsessions)
                {
                    $HDXSessionUserName = Get-BrokerSession -DNSName "$($MaintDevice)" -Protocol "HDX"| Where-Object {$_.Uid -eq $HDXsession} | % {$_.UserName}
                    Write-Log -Msg "Sending Information to HXD Session for User $HDXSessionUserName - Uid $HDXsession" -ShowConsole DarkCyan -SubMsg 
                    Send-BrokerSessionMessage -InputObject $HDXsession -MessageStyle Exclamation -Title "Reboot Warning" -Text "Information for $HDXSessionUserName - This Citrix Computer $MaintDevice is in Maintenance Mode and would be rebootet in $WaitInMinutes Minutes, please save your work and log off from Citrix. You can immediately log in through Citrix and start your work on a different Machine. "
                }           
            } ELSE {
                Write-Log -Msg "No HDX Session on $MaintDevice detected" -ShowConsole Green -SubMsg 

            }

            # Processing Console or RDP Session 
            $sessions = Get-BrokerSession -DNSName "$($MaintDevice)" | Where-Object {$_.Protocol -ne "HDX"} | % {$_.Uid}   
            IF (!($sessions -eq $null))
            {
                ForEach ($session in $sessions)
                {
                    $SessionUserName = Get-BrokerSession -DNSName "$($MaintDevice)" | Where-Object {$_.Uid -eq $session} | % {$_.UserName}
                    Write-Log -Msg "Sending Information to RDP/Console Session for User $SessionUserName - Uid $session" -ShowConsole DarkCyan -SubMsg 
                    Send-BrokerSessionMessage -InputObject $session -MessageStyle Exclamation -Title "Reboot Warning" -Text "Information for $SessionUserName - This Citrix Computer $MaintDevice is in Maintenance Mode and would be rebootet in $WaitInMinutes Minutes."
                }           
            } 
        
        }
    }
    Write-Log -Msg "Wait $WaitInMinutes Minutes ($($Wait1) Seconds) to proceed and reboot Maintenance VM's" -ShowConsole Cyan 
    Start-Sleep -Seconds $Wait1

    Write-Host ""
    Write-Host ""

    Write-Log -Msg "Starting Reboot Process now" -ShowConsole Cyan 
    ForEach ($XDBroker in $XDBrokers)
    {
        Write-Log -Msg "Processing XenDesktop Broker $XDBroker" -ShowConsole Cyan
        $MaintDevices = Get-BrokerMachine -AdminAddress "$XDBroker" | Where-Object {$_.InMaintenanceMode -eq $true} | % {$_.DNSName}
        
        $i = 0 
        ForEach ($MaintDevice in $MaintDevices)
        {
            Write-Host ""
            Write-Log -Msg "Processing Maintenance Devices $MaintDevice on XDBroker $XDBroker" -ShowConsole Yellow
            
            # Processing All Sessions and send final Warning to reboot now
            $Allsessions = Get-BrokerSession -DNSName "$($MaintDevice)" | % {$_.Uid}
            ForEach ($Allsession in $Allsessions)
            {
                $AllSessionUserName = Get-BrokerSession -DNSName "$($MaintDevice)" | Where-Object {$_.Uid -eq $Allsession} | % {$_.UserName}
                Write-Log -Msg "Sending Information to User $SessionUserName - Uid $Allsession" -ShowConsole -Color DarkYellow -SubMsg 
                Send-BrokerSessionMessage -InputObject $Allsession -MessageStyle Exclamation -Title "Reboot Warning" -Text "Information for $AllSessionUserName - Reboot Limit with $WaitInMinutes Minutes is reached, the Citrix Computer $MaintDevice would rebooted now !!!"
            }
            
            
            $ErrorActionPreference = "Stop"
               try {
   
               Write-Log -Msg "Reboot Maintenance Devices $MaintDevice now" -ShowConsole -Color DarkYellow -SubMsg
               Restart-Computer -force -ComputerName $MaintDevice 	
		            } # end try
            catch {
                              
                Write-Log -Msg "$_.Exception.GetType().FullName, $_.Exception.Message " -ShowConsole -Color Red -SubMsg -Type W
            } # end  

            finally {
                $ErrorActionPreference = "Continue"
                IF ($i -eq $RebootCycle)
                {
                    Write-Host ""
                    Write-Log -Msg "Waiting $Wait2 seconds for next Reboot Cycle with the next $RebootCycle VM's" -ShowConsole -Color White
                    $i = 0
                    Start-Sleep -Seconds $Wait2
                }
                $i++
    
            }


        }
           
    }

}

End {
Add-FinishLine
Remove-Module Module
}

