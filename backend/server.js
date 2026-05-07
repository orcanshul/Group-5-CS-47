const express = require('express');
const multer  = require('multer');
const { execFile } = require('child_process');
const path  = require('path');
const fs    = require('fs');
const cors  = require('cors');

const app = express();
app.use(cors({ origin: ['http://localhost:5173', 'http://localhost:3000'] }));

// ── paths ──────────────────────────────────────────────────────────────────
const MIPS_DIR  = path.join(__dirname, '..');          // group5/ — where *.asm live
const MARS_JAR  = path.join(__dirname, 'mars', 'Mars4_5.jar');
const UPLOAD_DIR = path.join(__dirname, 'uploads');

if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// ── multer: short, space-free filenames so they fit the 128-byte MIPS buffer
const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 40);
    cb(null, `${Date.now()}_${safe}`);
  }
});
const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } });

// ── health check ──────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    marsReady: fs.existsSync(MARS_JAR),
    asmReady:  fs.existsSync(path.join(MIPS_DIR, 'web_cli.asm'))
  });
});

// ── main endpoint ─────────────────────────────────────────────────────────
app.post('/api/checksum', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

  const uploadedPath = req.file.path;

  if (!fs.existsSync(MARS_JAR)) {
    fs.unlinkSync(uploadedPath);
    return res.status(500).json({
      error: 'Mars4_5.jar not found. Place it in backend/mars/ then restart the server.'
    });
  }

  // Forward slashes work on all platforms inside Java/MARS
  const filePath = uploadedPath.replace(/\\/g, '/');

  const child = execFile(
    'java',
    ['-jar', MARS_JAR, 'nc', 'me', 'sm', 'web_cli.asm'],
    { cwd: MIPS_DIR, timeout: 30_000 },
    (error, stdout, stderr) => {
      try { fs.unlinkSync(uploadedPath); } catch {}

      if (error && !stdout.includes('Generated checksum')) {
        return res.status(500).json({
          error: stderr || error.message || 'MARS execution failed.',
          raw: stdout
        });
      }

      const match = stdout.match(/Generated checksum:\s*(-?\d+)/);
      res.json({
        checksum:  match ? match[1] : null,
        filename:  req.file.originalname,
        raw:       stdout
      });
    }
  );

  // MIPS reads the filename from stdin (syscall 8 / read_filename macro)
  child.stdin.write(filePath + '\n');
  child.stdin.end();
});

// ── serve built frontend in production / Docker ───────────────────────────
const publicDir = path.join(__dirname, 'public');
if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
  app.get('*', (req, res) => res.sendFile(path.join(publicDir, 'index.html')));
}

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`\nBackend  → http://localhost:${PORT}`);
  console.log(`MARS JAR → ${fs.existsSync(MARS_JAR) ? 'found ✓' : 'MISSING — place Mars4_5.jar in backend/mars/'}`);
  console.log(`ASM      → ${fs.existsSync(path.join(MIPS_DIR, 'web_cli.asm')) ? 'found ✓' : 'MISSING'}\n`);
});
