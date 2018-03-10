# Reboot Schedule - VM's in Maintenance Mode
 
As Citrix describes in their own blog, Reboot Schedule Internals, VDAs in Maintenance Mode would not be rebooted. I have created a simple Powershell Script that fullfills that.You can run the Script from the Controller itself or from any Admin-VM,  where you have installed Citrix Studio or the Powershell Commands for Citrix XenDesktop only.

It's possible to run the script as a scheduled task with your prefered day/time configuration. The account (e.g. FC-SVC-CTX-Maint) that runs with the scheduled task must have read access to each XenDesktop Site as a minimum.  

Script Configuration:
XDBrokers: In the Script itself, you can enter multiple XenDesktop Controllers for different sites.
Wait1: Wait Time in seconds between notfication and reboot cycle starts (default 1800 seconds = 30 minutes)
RebootCycle: How many Machines would be rebooted in one cycle
Wait 2: Wait time between reboot cycle (default 300seconds = 5 minutes)

Run the Script:If the script starts, it checks any HDX Session and sends out a message to each user. The message contains the Username and the DNS Hostname. A different message would be sent out to each console or RDP Session. The message notification would also reported to the logfile of the script. 

After the configured wait time ($wait1) the VDAs in state "Maintenance Mode ON" would also be captured. In the meanwhile, from starting the script to this point, the Maintenance Mode of the VDAs might be changed.If the Reboot cycle starts, it takes the number of VMs configured in $RebootCycle (default 10) and reboot this. Wait the number of seconds in $wait2 (default 300 seconds) and start the next $RebootCycle.  

The Reboot was not initiated through XenDesktop, because the script does not detect the Power Management of the Machine Catalog. The reboot would be performed through Stop-Computer with Powershell. All the steps are logged

