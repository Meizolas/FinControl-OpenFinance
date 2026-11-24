param([string]$UserEmail = 'titular.b@gmail.com')

$ErrorActionPreference = 'Stop'
$config = Get-Content (Join-Path $PSScriptRoot '..\.env') | ConvertFrom-StringData
$baseUrl = $config.SUPABASE_URL.TrimEnd('/')
$publicKey = $config.SUPABASE_ANON_KEY
if (-not $baseUrl -or -not $publicKey) { throw 'Configuração .env ausente.' }

$securePassword = Read-Host "Senha de teste de $UserEmail" -AsSecureString
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
  $password = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
  $body = @{ email = $UserEmail; password = $password } | ConvertTo-Json
  $session = Invoke-RestMethod -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Method Post -Headers @{ apikey = $publicKey } -ContentType 'application/json' -Body $body
} finally {
  if ($pointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
  $password = $null
  $body = $null
}

$headers = @{ apikey = $publicKey; Authorization = "Bearer $($session.access_token)" }
$roleResult = Invoke-RestMethod -Uri "$baseUrl/rest/v1/rpc/is_support" `
  -Method Post -Headers $headers -ContentType 'application/json' -Body '{}'
if ($roleResult -ne $false) { throw 'FALHA: titular comum foi identificado como suporte.' }

try {
  Invoke-RestMethod -Uri "$baseUrl/rest/v1/rpc/get_support_queue" `
    -Method Post -Headers $headers -ContentType 'application/json' -Body '{}'
  throw 'FALHA: titular comum conseguiu consultar a fila de suporte.'
} catch {
  $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
  if ($status -notin 401, 403) { throw }
}

Write-Host 'APROVADO: titular comum não possui papel support e a fila foi bloqueada pelo backend.'
