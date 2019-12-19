$ErrorActionPreference = 'Stop'

$ScriptName = $MyInvocation.MyCommand.Name
$ScriptPath = Split-Path -parent $MyInvocation.MyCommand.Definition

Start-Transcript -Path $ScriptPath\$ScriptName.txt

$TimeZone = "UTC"
$TimeServer = "pool.ntp.org"
$DNSServer = "8.8.8.8"

#------------------------------------End of variables, Start of Script------------------------------------------------------------------------------------------------------------

Set-Service W32Time -StartupType Automatic
Start-Service W32Time
Set-TimeZone -Id $TimeZone
do{Write-Host "Checking for $DNSServer availability..."}until((Test-NetConnection $DNSServer -Port 53 | Select-Object -ExpandProperty TcpTestSucceeded) -eq "True")

do{ Write-Host "Checking for $DNSServer availability..."
    $NTPIP = Resolve-DnsName $TimeServer -Server $DNSServer | Select-Object -ExpandProperty IPAddress | Get-Random -Count 1
    Write-Host "$NTPIP selected for NTP server."
    Start-Process w32tm.exe -ArgumentList "/config /manualpeerlist:$NTPIP /syncfromflags:manual /reliable:yes /update" -Wait
    w32tm.exe /resync
  }
until((Select-String -Path $ScriptPath\$ScriptName.txt -Pattern "The command completed successfully." -SimpleMatch -Quiet) -eq $true)

Stop-Transcript

$ErrorActionPreference = 'Continue'
