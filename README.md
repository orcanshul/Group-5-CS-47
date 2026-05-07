# File Hash Checksum Generator


### Problem: 
What if we want to check if a large file has been tampered with or changed?

### Security Concept: 
Data integrity, Tampering Detection

### How it works:
Transform the file into a smaller, collision-resistant representation and use this for comparison instead.
In other words, we generate two checksums and compare them since it'd be faster than a direct linear comparison between initial giant file and final giant file.

Input: 
- a file name

Expected output: 
- a checksum derived from the file, after performing SHA-256


### Why it matters: 
- Checking whether data has properly traversed some transfer method
- Determining whether data has been tampered with

## Requirements
- MARS simulator

## Usage
### Main entrypoint is in `FileReader.asm`
In MARS, view `FileReader.asm` and assemble and run.
