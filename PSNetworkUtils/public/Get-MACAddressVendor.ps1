function Get-MACAddressVendor {
  # TODO: Add comment-based help
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$MACAddress
  )

  begin {}

  process {

    foreach ($address in $MACAddress) {

      if ($address -match '^(?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})$') {

        $oui = $address.Substring(0, 8).ToUpper().Replace('-', ':')

        try {

          $vendor = (Invoke-RestMethod -Uri "https://api.macvendors.com/$oui" -ErrorAction Stop).Trim()

          if ([string]::IsNullOrWhiteSpace($vendor)) {

            $vendor = "Unknown Vendor"

          }

        } catch {

          $vendor = "Error retrieving vendor"

        }

        $output = [PSCustomObject]@{
          MACAddress = $address
          Vendor     = $vendor
        }

      } else {
        Write-Warning "Invalid MAC address format: $address"
      }

      Write-Output $output

    }

  }

  end {}

}