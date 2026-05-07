# setup.ps1 -- run once before "npm start"
# Downloads MARS 4.5 JAR and installs all npm dependencies.

$ErrorActionPreference = 'Stop'
$marsPath = Join-Path $PSScriptRoot 'backend\mars\Mars4_5.jar'

Write-Host ""
Write-Host "=== MIPS Checksum -- Setup ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check Java
Write-Host "Checking Java..." -NoNewline
try {
    $ver = (& java -version 2>&1)[0]
    Write-Host " OK ($ver)" -ForegroundColor Green
} catch {
    Write-Host " NOT FOUND" -ForegroundColor Red
    Write-Host "Java is required. Install from https://adoptium.net then re-run." -ForegroundColor Yellow
    exit 1
}

# 2. Download MARS JAR if needed
if (Test-Path $marsPath) {
    Write-Host "MARS JAR already present." -ForegroundColor Green
} else {
    Write-Host "Downloading MARS 4.5 JAR..." -NoNewline
    $url = 'https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar'
    try {
        Invoke-WebRequest -Uri $url -OutFile $marsPath -UseBasicParsing
        Write-Host " Done ($([Math]::Round((Get-Item $marsPath).Length/1MB,1)) MB)" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host ""
        Write-Host "Download Mars4_5.jar from:" -ForegroundColor Yellow
        Write-Host "  $url" -ForegroundColor Yellow
        Write-Host "and save it to: $marsPath" -ForegroundColor Yellow
        Write-Host "Then re-run: npm start" -ForegroundColor Yellow
        exit 1
    }
}

# 3. npm install
Write-Host "Installing root dependencies..."
npm install
Write-Host "Installing backend dependencies..."
npm --prefix backend install
Write-Host "Installing frontend dependencies..."
npm --prefix frontend install

Write-Host ""
Write-Host "=== Setup complete! ===" -ForegroundColor Green
Write-Host "Run:      npm start" -ForegroundColor Cyan
Write-Host "Then open: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
