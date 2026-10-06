# Builds the Rust half of the Windows client for one architecture and collects it under fixed names in OutputDirectory/<arch>. None of it depends on the edition (editions rename the host DLL afterwards, Build-Client.ps1), so a release builds it once and hands the result to every edition's Build-Client.ps1 -RustOutputs. Without -RustOutputs, Build-Client.ps1 runs this itself for all three architectures. This script never signs or installs.
#
# x64: lingyao_host_api.dll with its import library and PDB, lingyao-mcp.exe and its PDB, and the Tauri panel shell as LINGYAO.exe and LINGYAO.pdb.
# x86: the host DLL, import library and PDB, for the 32-bit TIP.
# arm64: the host DLL and PDB, with the C runtime linked statically like the TIP, for the native half of the Arm64X TIP. ring assembles its ARM64 code with clang only, so clang must be on PATH.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('x64', 'x86', 'arm64')][string]$Architecture,
    [Parameter(Mandatory)][string]$OutputDirectory,
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$TargetVersion = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($TargetVersion -ne '' -and
    ($TargetVersion -notmatch '^(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})\.(0|[1-9][0-9]{0,4})$' -or
     @($TargetVersion.Split('.') | Where-Object { [int]$_ -gt 65535 }).Count -ne 0)) {
    throw 'TargetVersion must have three numeric components between 0 and 65535 without leading zeros'
}
if (-not [IO.Path]::IsPathRooted($OutputDirectory)) { throw 'OutputDirectory must be an absolute path' }

function Invoke-RustBuild {
    param([string]$Command, [string[]]$Arguments)
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Client build command failed: $Command ($LASTEXITCODE)" }
}

# Rust and the toolchain can name a binary's PDB after the normalized crate name; take the one that exists and refuse stale or ambiguous symbols.
function Get-SinglePdb {
    param([string]$Release, [string[]]$Names, [string]$What)
    $found = @($Names | ForEach-Object { Join-Path $Release $_ } | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
    if ($found.Count -ne 1) { throw "Expected one $What PDB output" }
    $found[0]
}

$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$triple = switch ($Architecture) { 'x64' { 'x86_64-pc-windows-msvc' } 'x86' { 'i686-pc-windows-msvc' } 'arm64' { 'aarch64-pc-windows-msvc' } }
$output = Join-Path $OutputDirectory $Architecture
$previousTarget = $env:CARGO_TARGET_DIR
$previousDebug = $env:CARGO_PROFILE_RELEASE_DEBUG
$previousArm64Flags = $env:CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_RUSTFLAGS
$previousVersion = $env:LINGYAO_VERSION
Push-Location $RepoRoot
try {
    $env:CARGO_TARGET_DIR = Join-Path $RepoRoot 'target'
    $env:CARGO_PROFILE_RELEASE_DEBUG = '2'
    if ($Architecture -eq 'arm64') { $env:CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_RUSTFLAGS = '-C target-feature=+crt-static' }
    $release = Join-Path $env:CARGO_TARGET_DIR "$triple/release"
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    Invoke-RustBuild cargo @('build', '--locked', '--release', '--target', $triple, '-p', 'lingyao-host-api')
    # Take the host and its PDB now: the MCP and desktop builds below share this target directory and can rebuild host-api, rewriting the PDB under the same name. The copy keeps the file name the DLL records; Collect-Symbols.ps1 packs it.
    $hostFiles = @('lingyao_host_api.dll', 'lingyao_host_api.pdb')
    if ($Architecture -ne 'arm64') { $hostFiles += 'lingyao_host_api.dll.lib' }
    Invoke-RustBuild cmake (@('-E', 'copy_if_different') + @($hostFiles | ForEach-Object { Join-Path $release $_ }) + @($output))
    if ($Architecture -eq 'x64') {
        # lingyao-mcp --version 和 MCP 握手报告的版本（crates/mcp-server/build.rs）；没给 TargetVersion 时它读 platforms/windows/version.txt。
        if ($TargetVersion -ne '') { $env:LINGYAO_VERSION = $TargetVersion }
        Invoke-RustBuild cargo @('build', '--locked', '--release', '--target', $triple, '-p', 'lingyao-mcp-server', '--bin', 'lingyao-mcp')
        Invoke-RustBuild cmake @('-E', 'copy_if_different', (Join-Path $release 'lingyao-mcp.exe'), $output)
        $mcpPdb = Get-SinglePdb $release @('lingyao_mcp.pdb', 'lingyao-mcp.pdb') 'MCP server'
        Invoke-RustBuild cmake @('-E', 'copy_if_different', $mcpPdb, (Join-Path $output 'lingyao-mcp.pdb'))

        Invoke-RustBuild pnpm @('install', '--frozen-lockfile')
        Invoke-RustBuild pnpm @('--filter', '@lingyao/desktop', 'typecheck')
        $desktopBuild = @('--filter', '@lingyao/desktop', 'tauri', 'build', '--no-bundle', '--target', $triple)
        if ($TargetVersion -ne '') {
            # Pass a file rather than inline JSON: pnpm is a .cmd shim on Windows, and PowerShell hands batch files their arguments without escaping the embedded quotes.
            $versionConfig = Join-Path $output 'tauri-version.json'
            [IO.File]::WriteAllText($versionConfig, (@{ version = $TargetVersion } | ConvertTo-Json -Compress))
            $desktopBuild += @('--config', $versionConfig)
        }
        Invoke-RustBuild pnpm $desktopBuild
        Invoke-RustBuild cmake @('-E', 'copy_if_different', (Join-Path $release 'lingyao-desktop.exe'), (Join-Path $output 'LINGYAO.exe'))
        $desktopPdb = Get-SinglePdb $release @('lingyao_desktop.pdb', 'lingyao-desktop.pdb') 'Tauri desktop'
        Invoke-RustBuild cmake @('-E', 'copy_if_different', $desktopPdb, (Join-Path $output 'LINGYAO.pdb'))
    }
} finally {
    $env:CARGO_TARGET_DIR = $previousTarget
    $env:CARGO_PROFILE_RELEASE_DEBUG = $previousDebug
    $env:CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_RUSTFLAGS = $previousArm64Flags
    $env:LINGYAO_VERSION = $previousVersion
    Pop-Location
}
