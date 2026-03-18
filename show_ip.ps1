# show_ip.ps1 — Exibe a URL que deve ser digitada na TV
# Execute: .\show_ip.ps1

$ip = (Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*"    -and   # loopback
    $_.IPAddress -notlike "169.254.*" -and  # APIPA (sem DHCP)
    $_.IPAddress -notlike "172.*"    -and   # Docker/WSL virtual
    $_.InterfaceAlias -notlike "*Loopback*" -and
    $_.InterfaceAlias -notlike "*VPN*"      -and
    $_.InterfaceAlias -notlike "*vEthernet*"
  } |
  Sort-Object { $_.InterfaceAlias -notmatch "Wi-Fi|Wireless|Ethernet" } |
  Select-Object -First 1).IPAddress

if (-not $ip) {
  Write-Host "Nenhum IP de rede local encontrado." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  Digite na TV:" -ForegroundColor White
Write-Host "  http://$ip`:8080" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
