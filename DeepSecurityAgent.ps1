$currentPath=Split-Path -Parent $MyInvocation.MyCommand.Path
Start-Transcript -path "$currentPath\dsa_deploy.log" -append
try {
    $Splathashtable = @{
                        'Path' = "$env:windir\Microsoft.NET\assembly\";
                        'Filter' = 'Microsoft.WindowsAzure.ServiceRuntime.dll';
                        'Include' = '*.dll'
                        }
    $dllfile = Get-ChildItem @Splathashtable -Recurse  | Select-Object -Last 1
    echo "$(Get-Date -format T) - Azure ServiceRuntime.dll loaded"
    
    Add-Type -Path $dllfile.FullName    
    $managerurl = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.ManagerUrl')
    $tenantid = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.TenantId')
    $tenantpassword = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.TenantPassword')
    $policyname = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.PolicyName')
    $groupname = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.GroupName')
    $displayname = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::CurrentRoleInstance.Id
    $description = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetConfigurationSettingValue('DeepSecurity.Description')
    echo "$(Get-Date -format T) - Azure ServiceConfiguration loaded"
}
catch {
    throw $_.exception
    echo "$(Get-Date -format T) - Azure ServiceRuntime load failed"
}
echo "$(Get-Date -format T) - DSA download started"
try {
    (New-Object System.Net.WebClient).DownloadFile("https://app.deepsecurity.trendmicro.com:443/software/agent/Windows/x86_64/", "$env:temp\agent.msi")
}
catch {
    echo "$(Get-Date -format T) - Agent file download failed"
    throw $_.exception
}
echo "$(Get-Date -format T) - Downloaded File Size:" (Get-Item "$env:temp\agent.msi").length
echo "$(Get-Date -format T) - DSA install started"
echo "$(Get-Date -format T) - Installer Exit Code:" (Start-Process -FilePath msiexec -ArgumentList "/i $env:temp\agent.msi /qn ADDLOCAL=ALL /l*v `"$env:LogPath\dsa_install.log`"" -Wait -PassThru).ExitCode 
echo "$(Get-Date -format T) - DSA activation started"
Start-Sleep -s 50
& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -r
& $Env:ProgramFiles"\Trend Micro\Deep Security Agent\dsa_control" -a $managerurl "tenantID:$tenantid" "tenantPassword:$tenantpassword" "group:$groupname" "policy:$policyname" "displayname:$displayname" "description:$description"
Stop-Transcript
echo "$(Get-Date -format T) - DSA Deployment Finished"
exit 0
