#!/usr/bin/env node
'use strict';
// Plaintext crosses anonymous pipes only. Passwords are never command arguments.
const fs = require('fs');
const crypto = require('crypto');
const LIMIT = 96 * 1024 * 1024;
const MAGIC = 'AI-IDE-PRIVATE-PROVIDERS-1';
try {
    const [mode, passwordPath] = process.argv.slice(2);
    if (!['encrypt', 'decrypt'].includes(mode) || !passwordPath) throw Error();
    const st = fs.lstatSync(passwordPath);
    if (!st.isFile() || st.isSymbolicLink() || (st.mode & 0o077) || st.uid !== process.getuid() || st.size > 4096) throw Error();
    let passphrase = fs.readFileSync(passwordPath);
    // One conventional text-file line ending is not part of the passphrase.
    if (passphrase[passphrase.length - 1] === 10) passphrase = passphrase.subarray(0, passphrase.length - (passphrase[passphrase.length - 2] === 13 ? 2 : 1));
    if (passphrase.length < 16) throw Error();
    let size = 0;
    const chunks = [];
    process.stdin.on('data', chunk => {
        size += chunk.length;
        if (size > LIMIT) { process.stderr.write('Private transfer failed.\n'); process.exit(2); }
        chunks.push(chunk);
    });
    process.stdin.on('end', () => {
        try {
            const input = Buffer.concat(chunks);
            let output;
            if (mode === 'encrypt') {
                const salt = crypto.randomBytes(16), nonce = crypto.randomBytes(12);
                const key = crypto.scryptSync(passphrase, salt, 32, {N: 32768, r: 8, p: 1, maxmem: 64 * 1024 * 1024});
                const cipher = crypto.createCipheriv('aes-256-gcm', key, nonce);
                cipher.setAAD(Buffer.from(MAGIC));
                const data = Buffer.concat([cipher.update(input), cipher.final()]);
                output = Buffer.from(JSON.stringify({magic: MAGIC, salt: salt.toString('base64'), nonce: nonce.toString('base64'), tag: cipher.getAuthTag().toString('base64'), data: data.toString('base64')}));
                key.fill(0);
            } else {
                const envelope = JSON.parse(input.toString('utf8'));
                if (envelope.magic !== MAGIC || Object.keys(envelope).sort().join(',') !== 'data,magic,nonce,salt,tag') throw Error();
                const decode = (value, len) => {
                    if (typeof value !== 'string') throw Error();
                    const b = Buffer.from(value, 'base64');
                    if (b.toString('base64') !== value || (len && b.length !== len)) throw Error();
                    return b;
                };
                const salt = decode(envelope.salt, 16), nonce = decode(envelope.nonce, 12), tag = decode(envelope.tag, 16);
                const key = crypto.scryptSync(passphrase, salt, 32, {N: 32768, r: 8, p: 1, maxmem: 64 * 1024 * 1024});
                const decipher = crypto.createDecipheriv('aes-256-gcm', key, nonce);
                decipher.setAAD(Buffer.from(MAGIC));
                decipher.setAuthTag(tag);
                output = Buffer.concat([decipher.update(decode(envelope.data)), decipher.final()]);
                key.fill(0);
            }
            passphrase.fill(0);
            process.stdout.write(output);
        } catch (_) { process.stderr.write('Private transfer authentication failed.\n'); process.exitCode = 2; }
    });
} catch (_) { process.stderr.write('Private transfer setup failed.\n'); process.exitCode = 2; }
