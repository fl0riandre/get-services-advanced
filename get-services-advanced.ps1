function get-services-advanced (

      [parameter(Mandatory=$false)]    [String]$Computer = "localhost"

)

{

$services = (gwmi win32_service -ComputerName $computer | select name, displayname, state, startmode | sort startmode, name)

$servicetable = @()

foreach ($service in $services)
{
$servicename = $service.name
$servicedisplayname  = $service.DisplayName
$triggerpath = 'HKLM:\SYSTEM\CurrentControlSet\Services\' + $servicename + '\TriggerInfo\'

if ( $computer -eq "localhost" )
{ 
$trigger = test-path -Path $triggerpath
$servicestartup = sc.exe qc $servicename | select-string "START_TYPE"
}
else { 
$trigger = invoke-command -computername $computer -scriptblock { test-path $Using:triggerpath }
$servicestartup = invoke-command -computername $computer -scriptblock { sc.exe qc $Using:servicename }
$servicestartup = $servicestartup[4] 
}

$servicestartup = ($servicestartup -split ':')[1]
$servicestartup = $servicestartup.Substring(2)
$serviceobject = New-Object PSObject
$serviceobject | Add-Member -type NoteProperty -Name 'Name' -Value $servicename
$serviceobject | Add-Member -type NoteProperty -Name 'Display Name' -Value $servicedisplayname

if ($servicestartup.trim() -eq "DISABLED") { $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Disabled" }

elseif ($servicestartup.trim() -eq "DEMAND_START") {

if ( $trigger -eq $True ) 

						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Manual (Triggered)" }
else 						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Manual"}

					}

elseif ($servicestartup.trim() -eq "AUTO_START  (DELAYED)") {

if ( $trigger -eq $True ) 

						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Automatic (Triggered and Delayed)" }
else 						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Automatic (Delayed)"}

}


elseif ($servicestartup.trim() -eq "AUTO_START")   {

if ( $trigger -eq $True ) 

						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Automatic (Triggered)" }
else 						{ $serviceobject | Add-Member -type NoteProperty -Name 'Startup' -Value "Automatic"}

}

$servicetable += $serviceobject
}
$servicetable

}
