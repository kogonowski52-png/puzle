# SPDX-License-Identifier: MIT
# Local signing only. No key/password upload, no Play API calls.
[CmdletBinding()]
param(
    [string]$KeyDirectory = '',
    [string]$OutputDirectory = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Find-JavaTools {
    $roots = @()
    if ($env:JAVA_HOME) { $roots += $env:JAVA_HOME }
    if ($env:ProgramFiles) {
        $roots += (Join-Path $env:ProgramFiles 'Android\Android Studio\jbr')
        foreach ($vendor in @('Microsoft', 'Eclipse Adoptium', 'Java')) {
            $base = Join-Path $env:ProgramFiles $vendor
            if (Test-Path -LiteralPath $base) {
                $roots += @(Get-ChildItem -LiteralPath $base -Directory | Sort-Object Name -Descending | ForEach-Object { $_.FullName })
            }
        }
    }
    $command = Get-Command jarsigner -ErrorAction SilentlyContinue
    if ($command) { $roots += (Split-Path (Split-Path $command.Source -Parent) -Parent) }
    $suffix = ''
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { $suffix = '.exe' }
    foreach ($base in @($roots | Select-Object -Unique)) {
        $keytool = Join-Path $base ('bin/keytool' + $suffix)
        $jarsigner = Join-Path $base ('bin/jarsigner' + $suffix)
        if ((Test-Path -LiteralPath $keytool) -and (Test-Path -LiteralPath $jarsigner)) {
            return @{ Keytool = $keytool; Jarsigner = $jarsigner }
        }
    }
    throw "Nie znaleziono JDK. W PowerShell uruchom:`nwinget install --id Microsoft.OpenJDK.21 -e`nPotem uruchom podpisywanie ponownie."
}

function Invoke-JavaTool {
    param([string]$Tool, [string[]]$ToolArguments)
    # Windows PowerShell 5 treats captured native stderr as ErrorRecord objects.
    # Check the actual exit code, including for successful keytool diagnostics.
    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $lines = & $Tool @ToolArguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    $result = (@($lines) | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
    if ($exitCode -ne 0) { throw ('Blad narzedzia Java (kod ' + $exitCode + '): ' + $result) }
    return $result
}

function Get-CertificateFingerprint {
    param([string]$Text)
    $match = [regex]::Match($Text, '(?m)^\s*SHA256:\s*([0-9A-Fa-f:]+)\s*$')
    if (-not $match.Success) { throw 'Nie udalo sie odczytac SHA-256 certyfikatu.' }
    return $match.Groups[1].Value.Replace(':', '').ToLowerInvariant()
}

$previousPassword = $env:NEON_UPLOAD_PASSWORD
$temporaryBundle = $null
try {
    $metadata = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'production-artifact-validation.json') -Raw | ConvertFrom-Json
    if ([IO.Path]::GetFileName($metadata.artifact) -ne $metadata.artifact) { throw 'Nieprawidlowa nazwa pliku AAB.' }
    if ($metadata.mode -ne 'production' -or $metadata.signed -ne $false -or $metadata.artifact_checks_passed -ne $true) {
        throw 'Paczka nie zawiera sprawdzonego kandydata produkcyjnego.'
    }
    if ($metadata.admob.app_id -ne 'ca-app-pub-5988667220268461~2690935374' -or
        $metadata.admob.rewarded_id -ne 'ca-app-pub-5988667220268461/2523414410' -or
        $metadata.admob.interstitial_id -ne 'ca-app-pub-5988667220268461/3644924391') {
        throw 'Identyfikatory reklam nie zgadzaja sie z konfiguracja wlasciciela.'
    }
    $candidate = Join-Path $PSScriptRoot $metadata.artifact
    if ((Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant() -ne $metadata.sha256) {
        throw 'Suma SHA-256 AAB jest nieprawidlowa. Pobierz oryginalna paczke ponownie.'
    }
    $java = Find-JavaTools
    if (-not $KeyDirectory) {
        $neonProfilePath = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
        $KeyDirectory = Join-Path $neonProfilePath 'NeonBlockMaster-Signing'
    }
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'wynik' }
    $key = Join-Path $KeyDirectory 'neon-upload.p12'
    $newKey = -not (Test-Path -LiteralPath $key)
    Write-Host 'Neon Block Master: podpisanie lokalne. Nic nie jest wysylane do internetu.'
    Write-Host ('Klucz: ' + $key)
    if (-not $env:NEON_UPLOAD_PASSWORD) {
        $prompt = 'Haslo istniejacego klucza'
        if ($newKey) { $prompt = 'Ustal haslo nowego klucza (minimum 12 znakow, zachowaj je w menedzerze hasel)' }
        $secure = Read-Host $prompt -AsSecureString
        $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $env:NEON_UPLOAD_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer); $secure.Dispose() }
        if ($newKey) {
            if (-not $env:NEON_UPLOAD_PASSWORD -or $env:NEON_UPLOAD_PASSWORD.Length -lt 12) {
                throw 'Nowe haslo musi miec minimum 12 znakow.'
            }
            $confirmation = Read-Host 'Powtorz haslo nowego klucza' -AsSecureString
            $confirmationPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirmation)
            try {
                $samePassword = [String]::Equals(
                    [Runtime.InteropServices.Marshal]::PtrToStringBSTR($confirmationPointer),
                    $env:NEON_UPLOAD_PASSWORD, [StringComparison]::Ordinal)
            } finally {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($confirmationPointer)
                $confirmation.Dispose()
            }
            if (-not $samePassword) { throw 'Hasla sa rozne. Klucz nie zostal utworzony.' }
        }
    }
    if (-not $env:NEON_UPLOAD_PASSWORD) { throw 'Haslo nie moze byc puste.' }
    if ($newKey -and $env:NEON_UPLOAD_PASSWORD.Length -lt 12) { throw 'Nowe haslo musi miec minimum 12 znakow.' }
    New-Item -ItemType Directory -Path $KeyDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $locale = @('-J-Duser.language=en', '-J-Duser.country=US')
    if ($newKey) {
        Invoke-JavaTool -Tool $java.Keytool -ToolArguments ($locale + @(
            '-genkeypair', '-keystore', $key, '-storetype', 'PKCS12',
            '-storepass:env', 'NEON_UPLOAD_PASSWORD', '-alias', 'upload',
            '-keyalg', 'RSA', '-keysize', '4096', '-sigalg', 'SHA256withRSA',
            '-validity', '10000', '-dname', 'CN=Neon Block Master Upload,OU=Krystian Development'
        )) | Out-Null
        Write-Host 'Utworzono nowy klucz upload. Zrob jego prywatna kopie zapasowa.'
    } else {
        Write-Host 'Uzywam istniejacego klucza; nie tworze i nie nadpisuje go.'
    }
    $certificate = Invoke-JavaTool -Tool $java.Keytool -ToolArguments ($locale + @(
        '-list', '-v', '-keystore', $key, '-storepass:env', 'NEON_UPLOAD_PASSWORD', '-alias', 'upload'
    ))
    $fingerprint = Get-CertificateFingerprint $certificate
    if ($certificate -match 'CN=Android Debug' -or $fingerprint -eq '54ab76826c313997d97a8c73ec7a808b5fc230ccc2817f503df1b067134cf18d') {
        throw 'Klucz debugowy nie moze sluzyc do publikacji Google Play.'
    }
    $temporaryBundle = Join-Path $OutputDirectory ('podpis-' + [Guid]::NewGuid().ToString('N') + '.aab')
    Invoke-JavaTool -Tool $java.Jarsigner -ToolArguments ($locale + @(
        '-keystore', $key, '-storetype', 'PKCS12', '-storepass:env', 'NEON_UPLOAD_PASSWORD',
        '-sigalg', 'SHA256withRSA', '-digestalg', 'SHA-256', '-signedjar', $temporaryBundle, $candidate, 'upload'
    )) | Out-Null
    $verification = Invoke-JavaTool -Tool $java.Jarsigner -ToolArguments ($locale + @('-verify', $temporaryBundle))
    if ($verification -notmatch 'jar verified\.') { throw 'Nie potwierdzono podpisu AAB.' }
    $signedCertificate = Invoke-JavaTool -Tool $java.Keytool -ToolArguments ($locale + @('-printcert', '-jarfile', $temporaryBundle))
    if ((Get-CertificateFingerprint $signedCertificate) -ne $fingerprint) { throw 'Certyfikat AAB nie pasuje do klucza upload.' }
    $final = Join-Path $OutputDirectory ('neon-block-master-' + $metadata.version_name + '-play-signed.aab')
    Move-Item -LiteralPath $temporaryBundle -Destination $final -Force
    $temporaryBundle = $null
    $report = [ordered]@{
        artifact = [IO.Path]::GetFileName($final)
        sha256 = (Get-FileHash -LiteralPath $final -Algorithm SHA256).Hash.ToLowerInvariant()
        original_sha256 = $metadata.sha256
        upload_certificate_sha256 = $fingerprint
        package = $metadata.package
        version_name = $metadata.version_name
        version_code = $metadata.version_code
        signed_and_verified = $true
        policy_review_verified = $false
        play_upload_performed = $false
        pending = @('public privacy and app-ads hosting', 'Families SDK review', 'AdMob/UMP and Play Console declarations', 'device testing')
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'raport-podpisu.json') -Encoding UTF8
    Write-Host ''
    Write-Host ('PODPIS POTWIERDZONY: ' + $final)
    Write-Host ('Certyfikat SHA-256: ' + $fingerprint)
    Write-Host 'Klucza ani hasla nie wysylaj na GitHub ani na czat. Zachowaj prywatna kopie.'
    Write-Host 'Podpis nie potwierdza Families, hostingu ani zatwierdzenia Play. Przed uploadem dokoncz te sprawdzenia.'
} catch {
    Write-Host ('BLAD: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
} finally {
    $env:NEON_UPLOAD_PASSWORD = $previousPassword
    if ($temporaryBundle -and (Test-Path -LiteralPath $temporaryBundle)) { Remove-Item -LiteralPath $temporaryBundle -Force }
}
