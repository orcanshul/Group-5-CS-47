# setup.ps1 — run once before `npm start`
# Downloads MARS 4.5 JAR and installs all npm dependencies.

$ErrorActionPreference = 'Stop'
$marsPath = Join-Path $PSScriptRoot 'backend\mars\Mars4_5.jar'

Write-Host "`n=== MIPS Checksum — Setup ===`n" -ForegroundColor Cyan

# ── 1. Java ──────────────────────────────────────────────────────────────────
Write-Host "Checking Java..." -NoNewline
try {
    $javaVersion = & java -version 2>&1 | Select-Object -First 1
    Write-Host " OK ($javaVersion)" -ForegroundColor Green
} catch {
    Write-Host " NOT FOUND" -ForegroundColor Red
    Write-Host "Java is required to run MARS. Install it from https://adoptium.net and re-run this script." -ForegroundColor Yellow
    exit 1
}

# ── 2. MARS JAR ───────────────────────────────────────────────────────────────
if (Test-Path $marsPath) {
    Write-Host "MARS JAR already present, skipping download." -ForegroundColor Green
} else {
    Write-Host "Downloading MARS 4.5 JAR..." -NoNewline
    $url = 'http://courses.missouristate.edu/KenVollmar/MARS/MARS_4_5_Aug2014/Mars4_5.jar'
    try {
        Invoke-WebRequest -Uri $url -OutFile $marsPath -UseBasicParsing
        Write-Host " Done" -ForegroundColor Green
    } catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host @"

Could not download MARS automatically. Download it manually:
  URL : $url
  Save to : $marsPath

Then re-run this script (or just run: npm start).
"@ -ForegroundColor Yellow
        exit 1
    }
}

# ── 3. npm install ────────────────────────────────────────────────────────────
Write-Host "Installing root dependencies..."
npm install

Write-Host "Installing backend dependencies..."
npm --prefix backend install

Write-Host "Installing frontend dependencies..."
npm --prefix frontend install

Write-Host "`n=== Setup complete! ===" -ForegroundColor Green
Write-Host "Run:  npm start" -ForegroundColor Cyan
Write-Host "Then open:  http://localhost:5173`n" -ForegroundColor Cyan
