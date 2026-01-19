import http from 'node:http';
import { spawn } from 'node:child_process';
import { WebhookReceiver } from 'livekit-server-sdk';

const apiKey = process.env.LIVEKIT_API_KEY;
const apiSecret = process.env.LIVEKIT_API_SECRET;
if (!apiKey) throw new Error('Error: LIVEKIT_API_KEY is not set');
if (!apiSecret) throw new Error('Error: LIVEKIT_API_SECRET is not set');

const receiver = new WebhookReceiver(apiKey, apiSecret);

function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(c));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

function json(res, statusCode, payload) {
  const body = Buffer.from(JSON.stringify(payload));
  res.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': String(body.length),
  });
  res.end(body);
}

function spawnStart(roomName, trackId) {
  const child = spawn('/bin/bash', ['/app/start.sh', roomName, trackId], {
    env: process.env,
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  child.stdout.on('data', (d) =>
    process.stdout.write(`[start.sh:${roomName}:${trackId}] ${d}`)
  );
  child.stderr.on('data', (d) =>
    process.stderr.write(`[start.sh:${roomName}:${trackId}] ${d}`)
  );

  return { spawned: true };
}

function normalizeTrackType(type) {
  if (typeof type === 'string') return type.toLowerCase();
  if (typeof type === 'number') {
    if (type === 0) return 'audio';
    if (type === 1) return 'video';
    if (type === 2) return 'data';
  }
  return '';
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/healthz') {
      return json(res, 200, { ok: true });
    }

    if (
      req.method !== 'POST' ||
      !req.url ||
      req.url.split('?')[0] !== '/webhook'
    ) {
      return json(res, 404, { error: 'not_found' });
    }

    const authHeader = req.headers.authorization;
    if (typeof authHeader !== 'string' || authHeader.length === 0) {
      return json(res, 401, { error: 'unauthorized' });
    }

    const rawBody = await readBody(req);

    let event;
    try {
      event = await receiver.receive(
        rawBody.toString('utf8'),
        authHeader
      );
    } catch {
      return json(res, 401, { error: 'unauthorized' });
    }

    if (event?.event !== 'track_published') {
      return json(res, 200, { ok: true });
    }

    const roomName = event?.room?.name;
    const track = event?.track;
    const trackId = track?.sid;
    const trackType = normalizeTrackType(track?.type);
    if (typeof roomName !== 'string' || roomName.length === 0) {
      return json(res, 400, { error: 'bad_request' });
    }
    if (typeof trackId !== 'string' || trackId.length === 0) {
      return json(res, 400, { error: 'bad_request' });
    }
    if (trackType !== 'audio') {
      return json(res, 200, { ok: true });
    }

    return json(res, 200, {
      ok: true,
      started: spawnStart(roomName, trackId),
    });
  } catch {
    return json(res, 500, { error: 'internal_server_error' });
  }
});

server.listen(8080, '0.0.0.0');
