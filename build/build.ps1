Set-Content -Path "..\PSNetworkUtils\PSNetworkUtils.psm1" -Value ''
Get-ChildItem -Path "..\PSNetworkUtils\Public" -Filter *.ps1 | Get-Content | Add-Content -Path ..\PSNetworkUtils\PSNetworkUtils.psm1
Add-Content -Path "..\PSNetworkUtils\PSNetworkUtils.psm1" -Value "Export-ModuleMember -Function *"