# make_htpasswd.ps1 — Gera o .htpasswd com encoding ASCII (obrigatório para o nginx)
# Execute: .\make_htpasswd.ps1
#
# IMPORTANTE: Nunca use  docker run ... > .htpasswd  no PowerShell.
# O operador > grava em UTF-16, que o nginx não consegue ler — a autenticação falha silenciosamente.

$usuario = Read-Host "Usuario"
$senha   = Read-Host "Senha" -AsSecureString
$senhaPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($senha)
)

$hash = docker run --rm httpd:alpine htpasswd -nbm $usuario $senhaPlain

if ($LASTEXITCODE -ne 0 -or -not $hash) {
    Write-Host "Erro ao gerar o hash. O Docker esta rodando?" -ForegroundColor Red
    exit 1
}

# Grava em ASCII puro — unico encoding aceito pelo nginx
[System.IO.File]::WriteAllText(
    (Join-Path $PSScriptRoot ".htpasswd"),
    ($hash.Trim() + "`n"),
    [System.Text.Encoding]::ASCII
)

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "  .htpasswd gerado com sucesso"    -ForegroundColor Green
Write-Host "  Usuario: $usuario"               -ForegroundColor White
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Reinicie o container para aplicar:" -ForegroundColor Gray
Write-Host "  docker compose restart"           -ForegroundColor Yellow
Write-Host ""
