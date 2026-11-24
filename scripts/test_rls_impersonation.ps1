param(
  [string]$UserBEmail = 'titular.b@gmail.com',
  [Parameter(Mandatory = $true)]
  [string]$UserAId
)

$ErrorActionPreference = 'Stop'

function Read-EnvFile([string]$Path) {
  $values = @{}
  Get-Content -LiteralPath $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#')) {
      $separator = $line.IndexOf('=')
      if ($separator -gt 0) {
        $values[$line.Substring(0, $separator).Trim()] = $line.Substring($separator + 1).Trim()
      }
    }
  }
  return $values
}

if ($UserAId -notmatch '^[0-9a-fA-F-]{36}$') {
  throw 'UserAId deve ser o UUID do titular A exibido em Authentication > Users.'
}

$config = Read-EnvFile (Join-Path $PSScriptRoot '..\.env')
$baseUrl = $config['SUPABASE_URL'].TrimEnd('/')
$publicKey = $config['SUPABASE_ANON_KEY']
if (-not $baseUrl -or -not $publicKey) {
  throw 'SUPABASE_URL ou SUPABASE_ANON_KEY ausente no arquivo .env.'
}

$securePassword = Read-Host "Senha de teste de $UserBEmail" -AsSecureString
$passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
  $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
  $loginBody = @{ email = $UserBEmail; password = $plainPassword } | ConvertTo-Json
  $session = Invoke-RestMethod `
    -Uri "$baseUrl/auth/v1/token?grant_type=password" `
    -Method Post `
    -Headers @{ apikey = $publicKey } `
    -ContentType 'application/json' `
    -Body $loginBody
} finally {
  if ($passwordPointer -ne [IntPtr]::Zero) {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
  }
  $plainPassword = $null
  $loginBody = $null
}

$headers = @{ apikey = $publicKey; Authorization = "Bearer $($session.access_token)" }
$institutions = Invoke-RestMethod `
  -Uri "$baseUrl/rest/v1/institutions?name=eq.Banco%20Alfa&select=id&limit=1" `
  -Headers $headers
if (-not $institutions -or -not $institutions[0].id) {
  throw 'Banco Alfa não foi encontrado para o usuário B.'
}

$attempt = @{
  owner_id = $UserAId
  institution_id = $institutions[0].id
  purpose = 'Teste controlado de isolamento RLS'
  data_categories = @('Saldo')
  valid_until = (Get-Date).ToUniversalTime().AddDays(30).ToString('o')
  terms_version = '1.0'
} | ConvertTo-Json

try {
  Invoke-RestMethod `
    -Uri "$baseUrl/rest/v1/authorizations" `
    -Method Post `
    -Headers ($headers + @{ Prefer = 'return=minimal' }) `
    -ContentType 'application/json' `
    -Body $attempt
  throw 'FALHA DE SEGURANÇA: o backend aceitou a autorização em nome de A.'
} catch {
  $status = if ($_.Exception.Response) { [int]$_.Exception.Response.StatusCode } else { 0 }
  if ($status -in 401, 403) {
    Write-Host "APROVADO: Supabase bloqueou a personificação via RLS (HTTP $status)."
    exit 0
  }
  throw
}
