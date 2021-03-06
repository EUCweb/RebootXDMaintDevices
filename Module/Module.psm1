function Set-LogFilePath {
 Param( 
	    [Parameter(Mandatory=$True)][Alias('P')][String]$LFP
	)
	If (!(Test-Path -Path $LFP)) {New-Item -Path $LFP -ItemType Directory -Force | Out-Null}
}

function add-STEPLine
{
	Write-Log -Msg "----- ----- ----- NEXT STEP ----- ----- -----"
}

function add-FinishLine
{
	Write-Log -Msg "----- ----- ----- FINISH ----- ----- -----"
}

function write-log {
    <#
    .SYNOPSIS
        Write the Logfile 
	.Description
      	Helper Function to Write Log Messages to Console Output and corresponding Logfile
		use get-help <functionname> -full to see full help
    .EXAMPLE
		write-log -Msg "Warining Text" -Type W
	.EXAMPLE
		write-log -Msg "Text would be shown on Console" -ShowConsole
	.EXAMPLE
		write-log -Msg "Text would be shown on Console in Cyan Color, information status" -ShowConsole -Color Cyan
	.EXAMPLE
		write-log -Msg "Error text, script would be existing automaticaly after this message" -Type E
	.EXAMPLE
		write-log -Msg "External log contenct" -Type L
    .Inputs
    .Outputs
    .NOTES
		Author: Matthias Schlimm
      	Company: Login Consultants Germany GmbH
		
		History
      	Last Change: dd.mm.yyyy MS: funtion created
		Last Change: 07.09.2015 MS: add .SYNOPSIS to this function
        Last Change: 29.09.2015 MS: add switch -SubMSg to define PreMsg string on each console line
	.Link
#>
	
	Param( 
	    [Parameter(Mandatory=$True)][Alias('M')][String]$Msg,
        [Parameter(Mandatory=$False)][Alias('S')][switch]$ShowConsole,  
	    [Parameter(Mandatory=$False)][Alias('C')][String]$Color = "",
        [Parameter(Mandatory=$False)][Alias('T')][String]$Type = "",
		[Parameter(Mandatory=$False)][Alias('B')][switch]$SubMsg,
        [Parameter(Mandatory=$False)][Alias('H')][switch]$ToHTML
        
	) 

	
	                     $LogType = "INFORMATION..."
    IF ($Type -eq "W" ) {$LogType = "WARNING..........."; $Color ="Yellow"}
    IF ($Type -eq "L" ) {$LogType = "EXTERNAL LOG...."; $Color ="DarkYellow"}
    IF ($Type -eq "E" ) {$LogType = "ERROR..............."; $Color ="Red"}

	IF (!($SubMsg))
	{
		$PreMsg = "+"
	} ELSE {
		$PreMsg = "`t>"
	}
	
    $date = get-date -Format G
    Out-File -Append -Filepath $logfile -inputobject "$date | $env:username | $LogType | $Msg" -Encoding default
	If (!($ShowConsole))
     {
        IF (($Type -eq "W") -or ($Type -eq "E" ))
        {
            IF ($VerbosePreference -eq 'SilentlyContinue')
            {
                Write-Host "$PreMsg $Msg" -ForegroundColor $Color
                #$Color = $null
            }
        } ELSE {
			Write-Verbose -Message "$PreMsg $Msg"
			#$Color = $null
        }		

	} ELSE {
	    if ($Color -ne "") 
        {
			IF ($VerbosePreference -eq 'SilentlyContinue')
            {
                Write-Host "$PreMsg $Msg" -ForegroundColor $Color
			    #$Color = $null
		    }
        } else {
			Write-Host "$PreMsg $Msg"
		}	
	}
    If ($ToHTML)
    {    
        $symbol = " chk"
        IF ($Color -eq "Yellow") {$symbol = " -->>"}
        IF ($Color -eq "red") {$symbol = " !! "}
        $Global:SumData+= @(
            [PSCustomObject]@{
                'Date / Time' = $(Get-Date)
                'Satus' = "[cell:$Color] $symbol"
                'Task' = "$Msg"
	        }	            
        )
        
    }
    $Color = $null
    IF ($Type -eq "E" ) {$Global:TerminateScript=$true;start-sleep 30;Exit}
} 

Function Invoke-HTML
{
    $HTML=$SumData | ConvertTo-AdvHTML -HeadWidth 0,0,800 | out-file $OutFile -append
    $Global:SumData=@()


}


Function ConvertTo-AdvHTML
{   <#
    .SYNOPSIS
        Advanced replacement of ConvertTo-HTML cmdlet
    .DESCRIPTION
        This function allows for vastly greater control over cells and rows
        in a HTML table.  It takes ConvertTo-HTML to a whole new level!  You
        can now specify what color a cell or row is (either dirctly or through 
        the use of CSS).  You can add links, pictures and pictures AS links.
        You can also specify a cell to be a bar graph where you control the 
        colors of the graph and text that can be included in the graph.
        
        All color functions are through the use of imbedded text tags inside the
        properties of the object you pass to this function.  It is important to note 
        that this function does not do any processing for you, you must make sure all 
        control tags are already present in the object before passing it to the 
        function.
        
        Here are the different tags available:
        
        Syntax                          Comment
        ===================================================================================
        [cell:<color>]<optional text>   Designate the color of the cell.  Must be 
                                        at the beginning of the string.
                                        Example:
                                            [cell:red]System Down
                                            
        [row:<color>]                   Designate the color of the row.  This control
                                        can be anywhere, in any property of the object.
                                        Example:
                                            [row:orchid]
                                            
        [cellclass:<class>]<optional text>  
                                        Designate the color, and other properties, of the
                                        cell based on a class in your CSS.  You must 
                                        have the class in your CSS (use the -CSS parameter).
                                        Must be at the beginning of the string.
                                        Example:
                                            [cellclass:highlight]10mb
                                            
        [rowclass:<class>]              Designate the color, and other properties, of the
                                        row based on a class in your CSS.  You must 
                                        have the class in your CSS (use the -CSS parameter).
                                        This control can be anywhere, in any property of the 
                                        object.
                                        Example:
                                            [rowclass:greyishbold]
                                            
        [image:<height;width;url>]<alternate text>
                                        Include an image in your cell.  Put size of picture
                                        in pixels and url seperated by semi-colons.  Format
                                        must be height;width;url.  You can also include other
                                        text in the cell, but the [image] tag must be at the
                                        end of the tag (so the alternate text is last).
                                        Example:
                                            [image:100;200;http://www.sampleurl.com/sampleimage.jpg]Alt Text For Image
                                            
        [link:<url>]<link text>         Include a link in your cell.  Other text is allowed in
                                        the string, but the [link] tag must be at the end of the 
                                        string.
                                        Example:
                                            blah blah blah [link:www.thesurlyadmin.com]Cool PowerShell Link
                                            
        [linkpic:<height;width;url to pic>]<url for link>
                                        This tag uses a picture which you can click on and go to the
                                        specified link.  You must specify the size of the picture and 
                                        url where it is located, this information is seperated by semi-
                                        colons.  Other text is allowed in the string, but the [link] tag 
                                        must be at the end of the string.
                                        Example:
                                            [linkpic:100;200;http://www.sampleurl.com/sampleimage.jpg]www.thesurlyadmin.com
                                            
        [bar:<percent;bar color;remainder color>]<optional text>
                                        Bar graph makes a simple colored bar graph within the cell.  The
                                        length of the bar is controlled using <percent>.  You can 
                                        designate the color of the bar, and the color of the remainder
                                        section.  Due to the mysteries of HTML, you must designate a 
                                        width for the column with the [bar] tag using the HeadWidth parameter.
                                        
                                        So if you had a percentage of 95, say 95% used disk you
                                        would want to highlight the remainder for your report:
                                        Example:
                                            [bar:95;dark green;red]5% free
                                        
                                        What if you were at 30% of a sales goal with only 2 weeks left in
                                        the quarter, you would want to highlight that you have a problem.
                                        Example:
                                            [bar:30;darkred;red]30% of goal
    .PARAMETER InputObject
        The object you want converted to an HTML table
    .PARAMETER HeadWidth
        You can specify the width of a cell.  Cell widths are in pixels
        and are passed to the parameter in array format.  Each element
        in the array corresponds to the column in your table, any element
        that is set to 0 will designate the column with be dynamic.  If you had
        four elements in your InputObject and wanted to make the 4th a fixed
        width--this is required for using the [bar] tag--of 600 pixels:
        
        -HeadWidth 0,0,0,600
    .PARAMETER CSS
        Designate custom CSS for your HTML
    .PARAMETER Title
        Specifies a title for the HTML file, that is, the text that appears between the <TITLE> tags.
    .PARAMETER PreContent
        Specifies text to add before the opening <TABLE> tag. By default, there is no text in that position.
    .PARAMETER PostContent
        Specifies text to add after the closing </TABLE> tag. By default, there is no text in that position.
    .PARAMETER Body
        Specifies the text to add after the opening <BODY> tag. By default, there is no text in that position.
    .PARAMETER Fragment
        Generates only an HTML table. The HTML, HEAD, TITLE, and BODY tags are omitted.
    .INPUTS
        System.Management.Automation.PSObject
        You can pipe any .NET object to ConvertTo-AdvHtml.
    .OUTPUTS
        System.String
        ConvertTo-AdvHtml returns series of strings that comprise valid HTML.
    .EXAMPLE
        $Data = @"
Server,Description,Status,Disk
[row:orchid]Server1,Hello1,[cellclass:up]Up,"[bar:45;Purple;Orchid]55% Free"
Server2,Hello2,[cell:green]Up,"[bar:65;DarkGreen;Green]65% Used"
Server3,Goodbye3,[cell:red]Down,"[bar:95;DarkGreen;DarkRed]5% Free"
server4,This is quite a cool test,[cell:green]Up,"[image:150;650;http://pughspace.files.wordpress.com/2014/01/test-connection.png]Test Images"
server5,SurlyAdmin,[cell:red]Down,"[link:http://thesurlyadmin.com]The Surly Admin"
server6,MoreSurlyAdmin,[cell:purple]Updating,"[linkpic:150;650;http://pughspace.files.wordpress.com/2014/01/test-connection.png]http://thesurlyadmin.com"
"@
        $Data = $Data | ConvertFrom-Csv
        $HTML = $Data | ConvertTo-AdvHTML -HeadWidth 0,0,0,600 -PreContent "<p><h1>This might be the best report EVER</h1></p><br>" -PostContent "<br>Done! $(Get-Date)" -Title "Cool Test!"
        
        This is some sample code where I try to put every possibile tag and use into a single set
        of data.  $Data is the PSObject 4 columns.  Default CSS is used, so the [cellclass:up] tag
        will not work but I left it there so you can see how to use it.
    .NOTES
        Author:             Martin Pugh
        Twitter:            @thesurlyadm1n
        Spiceworks:         Martin9700
        Blog:               www.thesurlyadmin.com
          
        Changelog:
            1.0             Initial Release
    .LINK
        http://thesurlyadmin.com/convertto-advhtml-help/
    .LINK
        http://community.spiceworks.com/scripts/show/2448-create-advanced-html-tables-in-powershell-convertto-advhtml
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true)]
        [Object[]]$InputObject,
        [string[]]$HeadWidth,
        [string]$CSS = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;font-size:120%;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"@,
        [string]$Title,
        [string]$PreContent,
        [string]$PostContent,
        [string]$Body,
        [switch]$Fragment
    )
    
    Begin {
        If ($Title)
        {   $CSS += "`n<title>$Title</title>`n"
        }
        $Params = @{
            Head = $CSS
        }
        If ($PreContent)
        {   $Params.Add("PreContent",$PreContent)
        }
        If ($PostContent)
        {   $Params.Add("PostContent",$PostContent)
        }
        If ($Body)
        {   $Params.Add("Body",$Body)
        }
        If ($Fragment)
        {   $Params.Add("Fragment",$true)
        }
        $Data = @()
    }
    
    Process {
        ForEach ($Line in $InputObject)
        {   $Data += $Line
        }
    }
    
    End {
        $Html = $Data | ConvertTo-Html @Params

        $NewHTML = @()
        ForEach ($Line in $Html)
        {   If ($Line -like "*<th>*")
            {   If ($Headwidth)
                {   $Index = 0
                    $Reg = $Line | Select-String -AllMatches -Pattern "<th>(.*?)<\/th>"
                    ForEach ($th in $Reg.Matches)
                    {   If ($Index -le ($HeadWidth.Count - 1))
                        {   If ($HeadWidth[$Index] -and $HeadWidth[$Index] -gt 0)
                            {   $Line = $Line.Replace($th.Value,"<th style=""width:$($HeadWidth[$Index])px"">$($th.Groups[1])</th>")
                            }
                        }
                        $Index ++
                    }
                }
            }
        
            Do {
                Switch -regex ($Line)
                {   "<td>\[cell:(.*?)\].*?<\/td>"
                    {   $Line = $Line.Replace("<td>[cell:$($Matches[1])]","<td style=""background-color:$($Matches[1])"">")
                        Break
                    }
                    "\[cellclass:(.*?)\]"
                    {   $Line = $Line.Replace("<td>[cellclass:$($Matches[1])]","<td class=""$($Matches[1])"">")
                        Break
                    }
                    "\[row:(.*?)\]"
                    {   $Line = $Line.Replace("<tr>","<tr style=""background-color:$($Matches[1])"">")
                        $Line = $Line.Replace("[row:$($Matches[1])]","")
                        Break
                    }
                    "\[rowclass:(.*?)\]"
                    {   $Line = $Line.Replace("<tr>","<tr class=""$($Matches[1])"">")
                        $Line = $Line.Replace("[rowclass:$($Matches[1])]","")
                        Break
                    }
                    "<td>\[bar:(.*?)\](.*?)<\/td>"
                    {   $Bar = $Matches[1].Split(";")
                        $Width = 100 - [int]$Bar[0]
                        If (-not $Matches[2])
                        {   $Text = "&nbsp;"
                        }
                        Else
                        {   $Text = $Matches[2]
                        }
                        $Line = $Line.Replace($Matches[0],"<td><div style=""background-color:$($Bar[1]);float:left;width:$($Bar[0])%"">$Text</div><div style=""background-color:$($Bar[2]);float:left;width:$width%"">&nbsp;</div></td>")
                        Break
                    }
                    "\[image:(.*?)\](.*?)<\/td>"
                    {   $Image = $Matches[1].Split(";")
                        $Line = $Line.Replace($Matches[0],"<img src=""$($Image[2])"" alt=""$($Matches[2])"" height=""$($Image[0])"" width=""$($Image[1])""></td>")
                    }
                    "\[link:(.*?)\](.*?)<\/td>"
                    {   $Line = $Line.Replace($Matches[0],"<a href=""$($Matches[1])"">$($Matches[2])</a></td>")
                    }
                    "\[linkpic:(.*?)\](.*?)<\/td>"
                    {   $Images = $Matches[1].Split(";")
                        $Line = $Line.Replace($Matches[0],"<a href=""$($Matches[2])""><img src=""$($Image[2])"" height=""$($Image[0])"" width=""$($Image[1])""></a></td>")
                    }
                    Default
                    {   Break
                    }
                }
            } Until ($Line -notmatch "\[.*?\]")
            $NewHTML += $Line
        }
        Return $NewHTML
    }
}

Function ConvertFrom-MCLI {
    Begin {
		$ErrorActionPreference= 'silentlycontinue'
        [array]$PvsLines = @()
    }

    Process {
        $PvsLines += $_
    }

    End {
        [array]$ResultArray = @()
        :NextLine ForEach ($Line in $PvsLines) {
            If ($Line.Length -eq 0) {Continue}
            If (($Line[0] -ne ” ” ) -or ($Line.StartsWith(” Record #” ))) {
                # New object reference
                If ($Line.StartsWith("Record #")) {
                    [Object]$Script:PvsObject = New-Object PSObject
                    $ResultArray += $Script:PvsObject
                    Continue NextLine
                } ElseIf ($Script:PvsObject -is [Object]) {
                    $ItemName = $([System.Text.RegularExpressions.Regex]::Replace($Line.Substring(0, $Line.IndexOf(":")),"[^1-9a-zA-Z_]","")) 
                    $ItemValue = $($Line.Substring($Line.IndexOf(":") + 2))
                    $Script:PvsObject | Add-Member -MemberType NoteProperty -Name $ItemName -Value $ItemValue
                }
            }
        }
        #Write-Host "Retrieved $($ResultArray.Count) objects"
        Return $ResultArray
    }
}

function Test-VMConnectivity {

[CmdletBinding( 
    DefaultParameterSetName = 'VMname' 
    )] 
param( 
    [Parameter(Mandatory = $False,ParameterSetName = '',ValueFromPipeline = $True)] [string]$VMname,
	[Parameter(Mandatory = $False,ParameterSetName = '',ValueFromPipeline = $True)] [Switch]$NoWait 
    )
	$sleep1 = 180
	$sleep2 = 60 
	IF (!($NoWait))
	{
		Write-Log "Waiting for VM $VMname is up und running, next Test in $sleep1 seconds" -ShowConsole -Color DarkGreen -SubMsg
		Start-Sleep -s $sleep1
	}
	Write-Log "flush the DNS Resolver Cache" -ShowConsole -Color DarkGreen -SubMsg
	Invoke-expression "ipconfig.exe /flushdns" | Out-Null
	$cnt = 0
	$timeout = 20
	$testpath="\\$($VMname)\c$"
	While (1 -eq 1) {
		IF (Test-Path $testpath) 
		{
    		Write-Log "Path $testpath available" -ShowConsole -Color DarkGreen -SubMsg -ToHTML
    		Write-Log "Waiting $sleep2 seconds to proceed...." -ShowConsole -Color DarkGreen -SubMsg
			Start-Sleep -s $sleep2
			return $true
			break
		}
		$cnt++
		IF (!($NoWait)) 
		{
			Write-Log "Retry $cnt/$timeout -Path $testpath NOT accessible, checking again in $sleep2 seconds" -Type W -SubMsg
			Start-Sleep -s $sleep2
		} else {
			Write-Log "Retry $cnt/$timeout -Path $testpath NOT accessible" -Type W -SubMsg -ToHTML
		}
		
		Invoke-expression "ipconfig.exe /flushdns" | Out-Null
		
		IF ($cnt -eq $timeout)
		{
			Write-Log "Timeout during connection to VM $VMname " Type W -SubMsg -ToHTML
			return $false
			break
		}
		
	}
	
	return = $false


}

function Invoke-LogRotate {
<#
    .SYNOPSIS
        Rotate Logfiles 
	.Description
      	Cleanup Logfiles and keep only a configured value of files
	
	.EXAMPLE
		Invoke-BISFLogRotate -Versions 5 -LogFileName "Prep*" -Directory "D:\BISFLogs"
    .Inputs
    .Outputs
    .NOTES
		Author: Benjamin Ruoff
      	Company: Login Consultants Germany GmbH
		
		History
      	Last Change: 15.03.2016 BR: function created
		Last Change: 17.03.2016 BR: Chane Remove-Item to delete the oldest log
		Last Change:

	.Link
#>
	Param( 
	    [Parameter(Mandatory=$True)][Alias('C')][int]$Versions,
        [Parameter(Mandatory=$False)][Alias('FN')][string]$strLogFileName,  
	    [Parameter(Mandatory=$True)][Alias('D')][string]$Directory
	)
	

    $LogFiles = Get-ChildItem -Path $Directory -Filter $strLogFileName | Sort-Object -Property LastWriteTime -Descending
	for ($i=$Versions; $i -le ($Logfiles.Count -1); $i++) {Remove-Item $LogFiles[$i].FullName}
    write-log -Msg "Cleaning Logfile ($strLogFileName) in $Directory and keep the last $Versions Logs"
	
} 


function Show-ProgressBar{
    PARAM(
		[parameter(Mandatory=$True)][string]$CheckProcess,
		[parameter(Mandatory=$True)][string]$ComputerName,
		[parameter(Mandatory=$false)][string]$ActivityText,
		[parameter(Mandatory=$false)][string]$ActivityTextFromLogFile
		
	)

    $a=0
	Start-Sleep 5
    for ($a=0; $a -lt 100; $a++) {
	IF ($a -eq "99") {$a=0}
	$ProcessActive = Get-Process -ComputerName $ComputerName -Processname $CheckProcess -ErrorAction SilentlyContinue
       	if($ProcessActive -eq $null) {
           	$a=100
           	Write-Progress -Activity "Finish...wait for next operation in 10 seconds" -PercentComplete $a -Status "Finish."
           	Start-Sleep 10
            Write-Progress "Done" "Done" -completed	
            break
       	} else {
           	Start-Sleep 1
           	$display= "{0:N2}" -f $a #reduce display to 2 digits on the right side of the numeric 
			IF ($ActivityTextFromLogFile -eq "")
			{
				Write-Progress -Activity "$ActivityText" -PercentComplete $a -Status "Please wait..."
			} ELSE {
				
				$ActTxt = Get-Content $ActivityTextFromLogFile -Encoding Unicode | Select-Object -Last 2
				Write-Progress -Activity "$ActTxt" -PercentComplete $a -Status "Please wait..."
			}
       	}
    }
}

function Get-LogContent
{
    PARAM(
		[parameter(Mandatory=$True)][string]$GetLogFile
	)
    write-log -Msg "Get content from file $GetLogFile...please wait" -ShowConsole -Color DarkGreen -SubMsg
    write-log -Msg "-----snip-----"
    $content = Get-Content "$GetLogFile" -Encoding Unicode
	#$content
    
	foreach ($line in $content) {
		Write-Log -Msg $line -Type L 
    }
    write-log -Msg "-----snap-----"
}

function Test-Log
{
  PARAM(
	[parameter(Mandatory=$True)][string]$CheckLogFile,
    [parameter(Mandatory=$True)][string]$SearchString
	)
    
   Write-Log -Msg "Check $CheckLogFile"
   IF (Test-Path ($CheckLogFile) -PathType Leaf)
   {
    	Write-Log -Msg "Check $CheckLogFile for $SearchString" 
    	$searchLog = select-string -path "$CheckLogFile" -pattern "$SearchString" -Encoding unicode | out-string
    	IF ($searchLog) {return $True} else {return $false}
    } ELSE {
    	Write-Log -Msg "File $CheckLogFile not exist" -Type E
    	$searchLog = "" 
    }
return $searchLog
}


function Convert-Logfile2HTML
{
	PARAM(
		[parameter(Mandatory=$True)][string]$computername,
		[parameter(Mandatory=$True)][string]$logfile,
		[parameter(Mandatory=$True)][string]$updcounter,
		[parameter(Mandatory=$True)][string]$vDiskName,
		[parameter(Mandatory=$True)][string]$HTMLfile
		
	) 
	$StartLine = Select-String -path "$logfile" -pattern "enumerating result" -Encoding unicode  | % {$_.LineNumber}
	$Data=@()
	for ($i=1; $i -le $updcounter; $i++)
	{
		$TXTDate = (Get-Content -Path $logfile -Encoding Unicode)[$StartLine] | % {$_.substring(0,19)} 
		$TXTupdate = (Get-Content -Path $logfile -Encoding Unicode)[$StartLine] | % {$_.Substring(21)} | % {$_.replace(":" ,"")}
		$StartLine = $StartLine + 1
		$TXTresult = (Get-Content -Path $logfile -Encoding Unicode)[$StartLine] | % {$_.Substring(35)}
		$StartLine = $StartLine + 1
		
		$Data+= @(
            [PSCustomObject]@{
                'Update' = "$TXTupdate"
                'Result Code' = "$TXTresult"
			}
            
        )	
		
		
	}
	$HTML=$Data | ConvertTo-AdvHTML -HeadWidth 0,0  -PreContent "<br>Update Status for vDisk $vDiskName on Base Image $computername - $TXTDate" | out-file $HTMLfile -append
	
}

function Test-Service {
PARAM(
		[parameter(Mandatory=$True)][string]$servicename,
		[parameter(Mandatory=$True)][string]$computername
	) 
	$service = Get-Service -ComputerName $($computername) -Name $($servicename) -ErrorAction SilentlyContinue

	IF ($service.Status -eq 'Stopped')
	{
		Set-Service -Name $servicename -StartupType Manual -ComputerName $($computername) | Out-Null
		Write-Log -Msg "Reconfigure $ServiceName on VM $($computername)" -ShowConsole -Color DarkGreen -SubMsg -ToHTML
		Get-Service -ComputerName $($computername) -Name $servicename | Start-Service
		Write-Log -Msg "Waiting 120 seconds to proceed.." -ShowConsole -Color DarkGreen -SubMsg
		Start-Sleep -Seconds 120
	} ELSE {
		Write-Log -Msg "Service $ServiceName is running on VM $($computername)" -ShowConsole -Color DarkGreen -SubMsg -ToHTML
	}
}

function convertToAccess($vDiskAccess) {

    switch($vDiskAccess){
        0 {"Production"; break}
        1 {"Maintenance"; break}
        2 {"MaintenanceHighestVersion"; break}
        3 {"Override"; break}
        4 {"Merge"; break}
        5 {"MergeMaintenance"; break}
        6 {"MergeTest"; break}
        7 {"Test"; break}
        default {$vDiskAccess; break}
    }
}


function convertToType($vDiskType) {

    switch($vDiskType){
        0 {"Base Disk"; break}
        1 {"Manual Disk"; break}
        2 {"Automatic"; break}
        3 {"Merge"; break}
        4 {"MergeBase"; break}
        default {$vDiskType; break}
    }
}


function convertToDeviceType($DeviceType) {

    switch($DeviceType){
        0 {"Production"; break}
        1 {"Test"; break}
        2 {"Maintenance"; break}
        default {$DeviceType; break}
    }
}

function convertToBootFrom($BootFrom) {

    switch($BootFrom){
        1 {"vDisk"; break}
        2 {"Hard Disk"; break}
        3 {"Floppy"; break}
        default {$BootFrom; break}
    }
}

function convertToWriteCacheType($WriteCache) {

    switch($WriteCache){
        0 {"Private"; break}
        1 {"Cache on Server"; break}
        3 {"Cache in Device RAM"; break}
		4 {"Cache in Device Hard Drive"; break}
		6 {"Device RAM Disk"; break}
		7 {"Cache on Server Persistent"; break}
		9 {"Cache in Device RAM with overflow on Hard Disk"; break}
        default {$WriteCache; break}
    }
}


function convertToStoreNumber($PVSStore) {

    switch($PVSStore){
       "XenApp 65" {"1"; break}
       "XenApp 5" {"2"; break}
	   "XenApp 76" {"3"; break}
        default {$PVSStore; break}
    }
}

Function Test-NeededPSSnapins
{
	Param([parameter(Mandatory = $True)][alias("Snapin")][string[]]$Snapins)

	#Function specifics
	$MissingSnapins = @()
	[bool]$FoundMissingSnapin = $False
	$LoadedSnapins = @()
	$RegisteredSnapins = @()

	#Creates arrays of strings, rather than objects, we're passing strings so this will be more robust.
	$loadedSnapins += Get-Pssnapin | % {$_.name}
	$registeredSnapins += Get-Pssnapin -Registered | % {$_.name}

	ForEach($Snapin in $Snapins)
	{
		#check if the snapin is loaded
		If(!($LoadedSnapins -like $snapin))
		{
			#Check if the snapin is missing
			If(!($RegisteredSnapins -like $Snapin))
			{
				#set the flag if it's not already
				If(!($FoundMissingSnapin))
				{
					$FoundMissingSnapin = $True
				}
				#add the entry to the list
				$MissingSnapins += $Snapin
			}
			Else
			{
				#Snapin is registered, but not loaded, loading it now:
				Add-PSSnapin -Name $snapin -EA 0 *>$Null
			}
		}
	}

	If($FoundMissingSnapin)
	{
		Write-Warning "Missing Windows PowerShell snap-ins Detected:"
		$missingSnapins | % {Write-Warning "($_)"}
		Return $False
	}
	Else
	{
		Return $True
	}
}
