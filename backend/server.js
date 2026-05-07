const express  = require('express');
const multer   = require('multer');
const { execFile } = require('child_process');
const path     = require('path');
const fs       = require('fs');
const cors     = require('cors');

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN?.split(',') ?? ['http://localhost:5173', 'http://localhost:3000'] }));

const MIPS_DIR   = path.join(__dirname, '..');
const MARS_JAR   = path.join(__dirname, 'mars', 'Mars4_5.jar');
const UPLOAD_DIR = path.join(__dirname, 'uploads');
const ASM_FILE   = path.join(MIPS_DIR, 'web_cli.asm');

fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// Cache existence checks at startup - no per-request filesystem hits
const marsReady = fs.existsSync(MARS_JAR);
const asmReady  = fs.existsSync(ASM_FILE);

const safeUnlink = (p) => fs.unlink(p, () => {});

const storage = multer.diskStorage({
  destination: UPLOAD_DIR,
  filename: (req, file, cb) => {
    const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_').slice(0, 40);
    cb(null, `${Date.now()}_${safe}`);
  }
});
const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } });

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', marsReady, asmReady });
});

app.post('/api/checksum', upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file uploaded.' });

  const uploadedPath = req.file.path;

  if (!marsReady) {
    safeUnlink(uploadedPath);
    return res.status(500).json({
      error: 'Mars4_5.jar not found. Place it in backend/mars/ then restart the server.'
    });
  }

  const filePath = uploadedPath.replace(/\\/g, '/');

  const child = execFile(
    'java',
    ['-jar', MARS_JAR, 'nc', 'me', 'sm', 'web_cli.asm'],
    { cwd: MIPS_DIR, timeout: 30_000 },
    (error, stdout, stderr) => {
      safeUnlink(uploadedPath);

      if (error && !stdout.includes('Generated checksum')) {
        return res.status(500).json({
          error: stderr || error.message || 'MARS execution failed.',
          raw: stdout
        });
      }

      const match = stdout.match(/Generated checksum:\s*(-?\d+)/);
      res.json({
        checksum: match ? match[1] : null,
        filename: req.file.originalname,
        raw:      stdout
      });
    }
  );

  child.stdin.write(filePath + '\n');
  child.stdin.end();
});

const publicDir = path.join(__dirname, 'public');
if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
  app.get('*', (req, res) => res.sendFile(path.join(publicDir, 'index.html')));
}

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`\nBackend  → http://localhost:${PORT}`);
  console.log(`MARS JAR → ${marsReady ? 'found ✓' : 'MISSING - place Mars4_5.jar in backend/mars/'}`);
  console.log(`ASM      → ${asmReady  ? 'found ✓' : 'MISSING'}\n`);
});
