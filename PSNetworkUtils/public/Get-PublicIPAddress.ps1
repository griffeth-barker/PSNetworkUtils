function Get-PublicIPAddress {
  <#
  .SYNOPSIS
    Retrieves the current public IP address of the machine.
  .DESCRIPTION
    This function fetches the current public IP address by querying a public API endpoint and returning it to the console.
  .INPUTS
    None
  .OUTPUTS
    A string containing the current public IP address (e.g. "8.8.8.8")
  .EXAMPLE
    Get-PublicIPAddress
    # Returns the current public IP address.
  .NOTES
    This function requires an active internet connection, as it uses a public API endpoint to determine your public IP address.
    The function is designed to be cross-platform and should work on Windows and Unix-like systems such as macOS and Linux.
    If on a Unix system, the Microosft.PowerShell.Management module must be present; if on a Windows system, the NetTCPIP module must be present.
  #>
  
  begin {
    $address = "ifconfig.me"
    if ($IsWindows) {
        $result = Test-NetConnection -ComputerName $address -WarningAction SilentlyContinue
        if ($result.PingSucceeded -ne $true) {
            Write-Error "Failed to reach the API endpoint. This function requires an active internet connection. Please check your network connection, then try again."
        }
    } else {
        $result = Test-Connection -TargetName $address -Count 1
        if ($result.Status -ne 'Success') {
            Write-Error "Failed to reach the API endpoint. This function requires an active internet connection. Please check your network connection, then try again."
        }
    }
  }

  process {
    $output = Invoke-RestMethod -Uri "https://ifconfig.me/ip"
    Write-Output $output
  }

  end {}
}