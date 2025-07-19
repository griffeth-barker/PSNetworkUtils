function New-RandomMACAddress {
    <#
    .SYNOPSIS
        Generates a MAC address.
    .DESCRIPTION
        This function generates a random MAC address. If specified, the MAC address will be generated using the vendor prefix (OUI) for
        the partial name of the vendor provided, if found in the IEEE OUI listing. See https://standards-oui.ieee.org/cid/cid.csv for the
        full OUI listing.

        The OUI listing is downloaded to the system's temp directory from the internet. If the OUI listing already exists, it will not be 
        downloaded again.
    .PARAMETER VendorPrefix
        The vendor whose prefix should be used to generate the MAC address. You can specify either the name of the vendor, or the prefix 
        itself.

        Type                : String
        Required            : False
        ValueFromPipeline   : False
    .EXAMPLE
        New-RandomMACAddress

        Generates a random MAC address with a randomly generated OUI
    .EXAMPLE
        New-RandomMACAddress -VendorPrefix 00-06-5B

        Generates a random MAC address with a specified OUI
    .EXAMPLE
        New-RandomMACAddress -VendorPrefix Sonos

        Generates a random MAC address with a specified vendor name
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$VendorPrefix
    )

    begin {
        # TODO: Add handling for Windows vs Unix
        if (-not (Test-Path -Path "$($env:TEMP)\macVendorPrefixes.csv") -and $VendorPrefix) {
            Invoke-WebRequest -Uri 'https://standards-oui.ieee.org/cid/cid.csv' -OutFile "$($env:TEMP)\macVendorPrefixes.csv"
            $lookupTable = Import-Csv -Path "$($env:TEMP)\macVendorPrefixes.csv"
        }
        
    }

    process {
        $sanitizedPrefix = $null

        if ($VendorPrefix) {
            if ($VendorPrefix -match '^([0-9A-Fa-f]{6}|([0-9A-Fa-f]{2}[-:]){2}[0-9A-Fa-f]{2})$') {
                $sanitizedPrefix = $VendorPrefix -replace '[-:]', ''
            }
            else {
                $vendorRow = $lookupTable | Where-Object { $_.'Organization Name' -like "*$VendorPrefix*" }
                if ($vendorRow) {
                    $oui = $vendorRow.Assignment -replace '[-:]', ''
                    $sanitizedPrefix = $oui
                }
                else {
                    Write-Error -Message "Vendor name or prefix not found: $VendorPrefix" -ErrorAction Stop
                }
            }
        }

        if ($sanitizedPrefix) {
            $prefixBytes = [byte[]]@(
                [Convert]::ToByte($sanitizedPrefix.Substring(0, 2), 16),
                [Convert]::ToByte($sanitizedPrefix.Substring(2, 2), 16),
                [Convert]::ToByte($sanitizedPrefix.Substring(4, 2), 16)
            )

            # TODO: Add default behavior to only generate compliant MAC addresses, with optional switch param to allow non-compliant MAC addresses.
            $randomBytes = Get-Random -Count 3 -Minimum 0 -Maximum 256
            $bytes = $prefixBytes + $randomBytes
        }
        else {
            $bytes = Get-Random -Count 6 -Minimum 0 -Maximum 256
            $bytes[0] = $bytes[0] -band 0xf0 -bor 0x2
        }

        $output = [BitConverter]::ToString($bytes) -replace '-', ':'
        Write-Output $output
    }

    end {}
}