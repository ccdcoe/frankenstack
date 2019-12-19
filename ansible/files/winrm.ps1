Enable-PSRemoting -SkipNetworkProfileCheck -Force
Set-NetFirewallRule RemoteDesktop* -Enabled true
Set-NetFirewallRule FPS* -Enabled true
Set-NetFirewallRule FPS-ICMP* -Profile Any
Set-NetFirewallRule WINRM-HTTP-In* -Profile Any
Enable-WSManCredSSP -Role Server -Force
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
