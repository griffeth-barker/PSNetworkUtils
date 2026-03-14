function Start-TcpProxy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, HelpMessage="The local port to listen on.")]
        [int]$LocalPort,

        [Parameter(Mandatory=$true, HelpMessage="The remote IP or Hostname to forward traffic to.")]
        [string]$RemoteHost,

        [Parameter(Mandatory=$true, HelpMessage="The remote port to forward traffic to.")]
        [int]$RemotePort
    )

    Write-Host "Starting TCP Proxy..." -ForegroundColor Cyan
    Write-Host "Listening on: 0.0.0.0:$LocalPort -> Forwarding to: $RemoteHost : $RemotePort"

    # Init listener
    $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $LocalPort)
    $listener.Start()

    try {
        Write-Host "Waiting for a client connection..."
        
        $client = $listener.AcceptTcpClient()
        $clientIp = $client.Client.RemoteEndPoint.ToString()
        Write-Host "Client connected from: $clientIp" -ForegroundColor Green

        Write-Host "Establishing connection to remote destination $RemoteHost : $RemotePort ..."
        
        $remoteClient = [System.Net.Sockets.TcpClient]::new()
        $remoteClient.Connect($RemoteHost, $RemotePort)
        Write-Host "Connected to remote destination." -ForegroundColor Green

        $clientStream = $client.GetStream()
        $remoteStream = $remoteClient.GetStream()

        
        $buffer = New-Object byte[] 8192   # Allocate an 8KB buffer for data transfer

        Write-Host "Proxy active. Relaying data... (Press Ctrl+C to stop)" -ForegroundColor Yellow

        # Relay loop <->
        while ($client.Connected -and $remoteClient.Connected) {
            $dataRelayed = $false

            # Client -> Remote
            if ($clientStream.DataAvailable) {
                $bytesRead = $clientStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $remoteStream.Write($buffer, 0, $bytesRead)
                    $dataRelayed = $true
                }
            }

            #  Remote -> Client
            if ($remoteStream.DataAvailable) {
                $bytesRead = $remoteStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    $clientStream.Write($buffer, 0, $bytesRead)
                    $dataRelayed = $true
                }
            }

            # Hoping to prevent max CPU util
            if (-not $dataRelayed) {
                Start-Sleep -Milliseconds 10
            }
        }
    }
    catch {
        Write-Error "A proxy error occurred: $_"
    }
    finally {
        Write-Host "Closing connection and stopping proxy..." -ForegroundColor Cyan
        
        if ($null -ne $clientStream) { $clientStream.Close() }
        if ($null -ne $remoteStream) { $remoteStream.Close() }
        if ($null -ne $client) { $client.Close() }
        if ($null -ne $remoteClient) { $remoteClient.Close() }
        
        $listener.Stop()
        Write-Host "Proxy offline."
    }
}
