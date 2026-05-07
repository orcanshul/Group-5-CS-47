import { useState, useRef } from 'react';
import './App.css';
import { Shader3 } from './components/Shader3';

export default function App() {
  const [file, setFile]         = useState(null);
  const [result, setResult]     = useState(null);
  const [error, setError]       = useState(null);
  const [loading, setLoading]   = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const [expected, setExpected] = useState('');
  const [showRaw, setShowRaw]   = useState(false);
  const fileInputRef = useRef();

  const pickFile = (f) => {
    setFile(f);
    setResult(null);
    setError(null);
  };

  const handleDrop = (e) => {
    e.preventDefault();
    setDragOver(false);
    const f = e.dataTransfer.files[0];
    if (f) pickFile(f);
  };

  const compute = async () => {
    if (!file || loading) return;
    setLoading(true);
    setError(null);
    setResult(null);

    const body = new FormData();
    body.append('file', file);

    try {
      const res  = await fetch('/api/checksum', { method: 'POST', body });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Server error');
      if (data.checksum === null) throw new Error('MIPS returned no checksum. Check MIPS output below.\n\n' + data.raw);
      setResult(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const matchStatus =
    result && expected.trim()
      ? result.checksum === expected.trim()
      : null;

  return (
    <>
      <Shader3 color="#c87028" />

      <div className="app">
        <header>
          <span className="badge">MIPS Reactor Core</span>
          <h1>File Checksum Verifier</h1>
          <p className="subtitle">Hash computed by MIPS assembly running on MARS</p>
        </header>

        <main>
          <div
            className={`drop-zone${dragOver ? ' drag-over' : ''}${file ? ' has-file' : ''}`}
            onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
            onDragLeave={() => setDragOver(false)}
            onDrop={handleDrop}
            onClick={() => fileInputRef.current.click()}
            role="button"
            tabIndex={0}
            onKeyDown={(e) => e.key === 'Enter' && fileInputRef.current.click()}
          >
            <input
              ref={fileInputRef}
              type="file"
              style={{ display: 'none' }}
              onChange={(e) => e.target.files[0] && pickFile(e.target.files[0])}
            />
            {file ? (
              <div className="file-info">
                <span className="file-icon">&#x1F4C4;</span>
                <div>
                  <div className="file-name">{file.name}</div>
                  <div className="file-meta">{(file.size / 1024).toFixed(1)} KB</div>
                </div>
              </div>
            ) : (
              <div className="drop-hint">
                <div className="drop-icon">&#x2B06;</div>
                <p>Drop a file here or click to browse</p>
              </div>
            )}
          </div>

          <div className="field">
            <label>Expected checksum <span className="optional">(optional for verification)</span></label>
            <input
              type="text"
              className="text-input mono"
              placeholder="Paste a previous checksum to compare..."
              value={expected}
              onChange={(e) => setExpected(e.target.value)}
            />
          </div>

          <button className="btn-primary" onClick={compute} disabled={!file || loading}>
            {loading ? (
              <><span className="spinner" /> Running MIPS&hellip;</>
            ) : (
              'Compute Checksum'
            )}
          </button>

          {error && (
            <div className="card error-card">
              <strong>Error</strong>
              <pre>{error}</pre>
            </div>
          )}

          {result && (
            <div className="card result-card">
              <div className="result-label">DJB2 Checksum</div>
              <div className="checksum-value">{result.checksum}</div>

              {matchStatus !== null && (
                <div className={`match ${matchStatus ? 'match-yes' : 'match-no'}`}>
                  {matchStatus ? '✓ Checksums match — file is unmodified' : '✗ Checksums differ — file may have changed'}
                </div>
              )}

              <button className="btn-link" onClick={() => setShowRaw(!showRaw)}>
                {showRaw ? 'Hide' : 'Show'} raw MIPS output
              </button>
              {showRaw && <pre className="raw-output">{result.raw}</pre>}
            </div>
          )}
        </main>

        <footer>
          <span className="mono">Special thanks to t^3</span>
          &nbsp;·&nbsp; Group 5 &amp; Ethan C Hachue
        </footer>
      </div>
    </>
  );
}
