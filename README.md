# MIPS File Checksum Verifier

**Authors:** Group 5

A file integrity tool that computes a SHA-256 checksum of any file using MIPS assembly running on the MARS simulator. Upload a file through the React web UI and the checksum is computed entirely inside the MIPS program - no shortcuts.

---

## How it works

```
Browser  →  React frontend (Vite, port 5173)
              ↓  POST /api/checksum  (multipart file upload)
         →  Express backend (Node.js, port 3001)
              ↓  saves file to backend/uploads/
              ↓  pipes file path to MARS via stdin
         →  MARS simulator  (runs MIPS assembly)
              ↓  web_cli.asm reads path from stdin (syscall 8)
              ↓  hash.asm opens file (syscall 13), reads in 4 KB chunks (syscall 14)
              ↓  computes SHA-256 digest (FIPS 180-4) across all file bytes
              ↓  prints "Generated checksum: <64-char hex>"
         →  backend parses the hex string, deletes the temp file, returns JSON
              ↓
         →  frontend displays the checksum
```

### The SHA-256 algorithm (in MIPS)

SHA-256 (FIPS 180-4) is a cryptographic hash that produces a 256-bit (32-byte) digest. The implementation processes the file in 64-byte blocks. Each block expands into a 64-word message schedule and is compressed through 64 rounds using bitwise operations (ROTR, XOR, AND, NOT) and modular addition. After all blocks are processed, the final padding block encodes the total message length as a 64-bit big-endian integer. The result is 8 × 32-bit words printed as a 64-character lowercase hex string.

### MIPS source files

| File | Purpose |
|---|---|
| `cli.asm` | Original CLI entry point - prompts for filename, calls hash_file, prints result |
| `hash.asm` | Core algorithm - opens file, reads 4 KB chunks, computes SHA-256, prints 64-char hex digest |
| `cli_macro.asm` | Helper macros: `print_string`, `print_int`, `read_filename`, `exit` |
| `FileReader.asm` | Alternative entry - same as cli.asm but also prints file contents |
| `web_cli.asm` | Web entry point - mirrors cli.asm but places `main:` before the hash.asm include so MARS headless mode (`-sm`) starts at the right instruction |

> `cli.asm`, `hash.asm`, `cli_macro.asm`, and `FileReader.asm` are the original, unmodified project files.

---

## Requirements

- **Node.js** 18+ - [nodejs.org](https://nodejs.org)
- **Java** 8+ - [adoptium.net](https://adoptium.net) (needed to run the MARS simulator)

---

## Setup (first time only)

```powershell
cd downloads/group5
.\setup.ps1
```

The script will:
1. Verify Java is installed
2. Download `Mars4_5.jar` (~4 MB) into `backend/mars/`
3. Run `npm install` for the root, backend, and frontend

If the automatic download fails, grab the JAR manually from  
`https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar`  
and place it at `backend/mars/Mars4_5.jar`.

---

## Running locally

```powershell
npm start
```

This starts both servers concurrently:

| Server | URL |
|---|---|
| React frontend | http://localhost:5173 |
| Express backend | http://localhost:3001 |

Open **http://localhost:5173** in your browser.

---

## Running with Docker

```powershell
docker compose up --build
```

The container installs Java, downloads MARS, builds the React app, and serves everything on **http://localhost:3001**.

---

## Using the app

1. **Drop a file** onto the upload area (or click to browse).
2. Click **Compute Checksum** - the file is sent to the backend, hashed by the MIPS program, and the result is displayed.
3. **Verify a file** by pasting a previously computed checksum into the "Expected checksum" field before clicking Compute. The app will tell you whether the checksums match, indicating the file is unmodified.

---

## Project structure

```
group5/
├── cli.asm            original MIPS CLI entry point
├── hash.asm           SHA-256 implementation in MIPS
├── cli_macro.asm      MIPS helper macros
├── FileReader.asm     alternative MIPS entry (also prints file contents)
├── web_cli.asm        web-specific MIPS entry point (main: label for headless MARS)
├── backend/
│   ├── server.js      Express API server
│   ├── package.json
│   └── mars/
│       └── Mars4_5.jar   MARS simulator (downloaded by setup.ps1)
├── frontend/
│   ├── src/
│   │   ├── App.jsx    React UI
│   │   └── App.css
│   ├── vite.config.js proxies /api to backend:3001
│   └── package.json
├── package.json       root - "npm start" runs both servers
├── setup.ps1          one-time setup script
├── Dockerfile         Docker build
└── docker-compose.yml
```

---

## API

### `POST /api/checksum`

Accepts a `multipart/form-data` request with a single `file` field.

**Response (success):**
```json
{
  "checksum": "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824",
  "filename": "example.txt",
  "raw": "Enter file path: \nGenerated checksum: 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824\n"
}
```

**Response (error):**
```json
{ "error": "description of what went wrong" }
```

### `GET /api/health`

```json
{ "status": "ok", "marsReady": true, "asmReady": true }
```
