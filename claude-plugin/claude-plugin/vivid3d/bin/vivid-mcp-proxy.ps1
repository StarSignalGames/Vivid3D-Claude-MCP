# Vivid3D MCP stdio <-> HTTP proxy.
#
# Claude launches this script as a stdio MCP server. It forwards every JSON-RPC line to the Vivid3D editor's
# built-in MCP endpoint (HTTP, 127.0.0.1) with the bearer token the editor writes to %LOCALAPPDATA%\Vivid3D\mcp.token.
# The editor is a persistent, separately started process: this proxy NEVER starts it and never guesses where it is installed.
# If the editor is not reachable it answers requests with an error that tells Claude to ask the user for the full path
# of Vivid3D.exe (see the vivid3d skill, "Starting the editor").

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http

$utf8 = New-Object System.Text.UTF8Encoding($false)
$stdout = New-Object System.IO.StreamWriter([Console]::OpenStandardOutput(), $utf8)
$stdout.AutoFlush = $true
$stdin = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), $utf8)

$dataDir = Join-Path $env:LOCALAPPDATA 'Vivid3D'
$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [TimeSpan]::FromMinutes(6)

function Get-Endpoint {
    $f = Join-Path $dataDir 'mcp.endpoint'
    if (Test-Path $f) { return (Get-Content $f -Raw).Trim() }
    return 'http://127.0.0.1:8765/mcp'
}

function Get-Token {
    $f = Join-Path $dataDir 'mcp.token'
    if (Test-Path $f) { return (Get-Content $f -Raw).Trim() }
    return ''
}

function Write-RpcError($id, $message) {
    $obj = [ordered]@{ jsonrpc = '2.0'; id = $id; error = [ordered]@{ code = -32000; message = $message } }
    $stdout.WriteLine(($obj | ConvertTo-Json -Compress -Depth 5))
}

$notRunning = 'The Vivid3D editor is not reachable. It is a separate, persistent program that must already be running (it hosts the MCP bridge, which is on by default). ' +
    'Do NOT guess an install path: ask the user for the full path of Vivid3D.exe they use, start it for them with that exact path (or ask them to start it), ' +
    'then ask them to reconnect this MCP server (/mcp). See the vivid3d skill, section "Starting the editor".'

while ($null -ne ($line = $stdin.ReadLine())) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }

    $id = $null
    $hasId = $false
    try {
        $msg = $line | ConvertFrom-Json
        if ($msg.PSObject.Properties.Name -contains 'id') { $hasId = $true; $id = $msg.id }
    } catch { }

    try {
        $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Post, (Get-Endpoint))
        $req.Headers.TryAddWithoutValidation('Authorization', 'Bearer ' + (Get-Token)) | Out-Null
        $req.Content = New-Object System.Net.Http.StringContent($line, $utf8, 'application/json')
        $resp = $client.SendAsync($req).GetAwaiter().GetResult()
        $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()

        if ([int]$resp.StatusCode -eq 401) {
            if ($hasId) { Write-RpcError $id 'The Vivid3D editor rejected the token (it was probably restarted with a different --mcp-token). Reconnect this MCP server (/mcp).' }
            continue
        }
        if (-not [string]::IsNullOrWhiteSpace($body)) { $stdout.WriteLine(($body -replace "\r?\n", ' ')) }
    } catch {
        if ($hasId) { Write-RpcError $id $notRunning }
    }
}
