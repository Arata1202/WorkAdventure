import http from 'node:http';
import { spawn } from 'node:child_process';
import fs from 'node:fs/promises';
import path from 'node:path';
import { RoomServiceClient, WebhookReceiver } from 'livekit-server-sdk';

const apiKey = process.env.LIVEKIT_API_KEY;
if (!apiKey) throw new Error('Error: LIVEKIT_API_KEY is not set');

const apiSecret = process.env.LIVEKIT_API_SECRET;
if (!apiSecret) throw new Error('Error: LIVEKIT_API_SECRET is not set');

const metaJsonlPath = process.env.META_JSONL_PATH;
if (!metaJsonlPath) throw new Error('Error: META_JSONL_PATH is not set');

const livekitHost = process.env.LIVEKIT_URL;
if (!livekitHost) throw new Error('Error: LIVEKIT_URL is not set');

const recordingRoomList = (process.env.RECORDING_ALLOWED_ROOMS || '')
  .split(',')
  .map((value) => value.trim())
  .filter((value) => value.length > 0);

const roomService = new RoomServiceClient(livekitHost, apiKey, apiSecret);
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

function spawnStart(
  roomName,
  trackId,
  meetingDate,
  meetingTime,
  trackTime,
  speakerName
) {
  const child = spawn(
    '/bin/bash',
    [
      '/app/start.sh',
      roomName,
      trackId,
      meetingDate,
      meetingTime,
      trackTime,
      speakerName,
    ],
    {
      env: process.env,
      stdio: ['ignore', 'pipe', 'pipe'],
    }
  );

  child.stdout.on('data', (d) =>
    process.stdout.write(
      `[start.sh:${roomName}:${trackId}:${meetingTime}:${trackTime}:${speakerName}] ${d}`
    )
  );
  child.stderr.on('data', (d) =>
    process.stderr.write(
      `[start.sh:${roomName}:${trackId}:${meetingTime}:${trackTime}:${speakerName}] ${d}`
    )
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

function isRecordingRoomAllowed(roomName) {
  if (!recordingRoomList.length) return true;
  return recordingRoomList.some((value) => {
    if (value.includes('localWorld.')) {
      return roomName === value;
    }
    return roomName.endsWith(value);
  });
}

const ROOM_START_TTL_MS = 1000 * 60 * 60 * 24;
const roomStartTimes = new Map();
const NAME_CACHE_TTL_MS = 1000 * 60 * 30;
const participantNameCache = new Map();

function toDateFromTimestamp(value) {
  if (value == null) return null;
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed;
    const numeric = Number(value);
    if (Number.isFinite(numeric)) return toDateFromTimestamp(numeric);
    return null;
  }
  if (typeof value !== 'number' || !Number.isFinite(value)) return null;
  let ms;
  if (value >= 1e14) {
    ms = Math.round(value / 1e6);
  } else if (value >= 1e11) {
    ms = Math.round(value);
  } else if (value >= 1e9) {
    ms = Math.round(value * 1000);
  } else {
    return null;
  }
  return new Date(ms);
}

function formatDateLocal(date) {
  const parts = new Intl.DateTimeFormat('ja-JP', {
    timeZone: 'Asia/Tokyo',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
  }).formatToParts(date);
  const year = parts.find((p) => p.type === 'year')?.value ?? '0';
  const month = parts.find((p) => p.type === 'month')?.value ?? '0';
  const day = parts.find((p) => p.type === 'day')?.value ?? '0';
  const monthNum = Number.parseInt(month, 10);
  const dayNum = Number.parseInt(day, 10);
  const safeMonth = Number.isFinite(monthNum) ? String(monthNum) : '0';
  const safeDay = Number.isFinite(dayNum) ? String(dayNum) : '0';
  return `${year}年${safeMonth}月${safeDay}日`;
}

function formatTimeLocal(date) {
  const parts = new Intl.DateTimeFormat('ja-JP', {
    timeZone: 'Asia/Tokyo',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
    hour12: false,
  }).formatToParts(date);
  const hours = parts.find((p) => p.type === 'hour')?.value ?? '0';
  const minutes = parts.find((p) => p.type === 'minute')?.value ?? '0';
  const seconds = parts.find((p) => p.type === 'second')?.value ?? '0';
  const hoursNum = Number.parseInt(hours, 10);
  const minutesNum = Number.parseInt(minutes, 10);
  const secondsNum = Number.parseInt(seconds, 10);
  const safeHours = Number.isFinite(hoursNum) ? String(hoursNum) : '0';
  const safeMinutes = Number.isFinite(minutesNum) ? String(minutesNum) : '0';
  const safeSeconds = Number.isFinite(secondsNum) ? String(secondsNum) : '0';
  return `${safeHours}時${safeMinutes}分${safeSeconds}秒`;
}

function trackRoomStart(roomName, startedAt) {
  if (!roomName) return;
  const now = Date.now();
  roomStartTimes.set(roomName, { startedAt, updatedAt: now });
  for (const [name, entry] of roomStartTimes) {
    if (now - entry.updatedAt > ROOM_START_TTL_MS) {
      roomStartTimes.delete(name);
    }
  }
}

async function appendRecord(entry) {
  try {
    await fs.mkdir(path.dirname(metaJsonlPath), { recursive: true });
    await fs.appendFile(metaJsonlPath, `${JSON.stringify(entry)}\n`);
  } catch (err) {
    process.stderr.write(
      `[records] failed to append ${metaJsonlPath}: ${err}\n`
    );
  }
}

async function resolveParticipantName(roomName, participantIdentity, trackId) {
  const cacheKey = `${roomName || ''}::${participantIdentity || ''}`;
  const cached = participantNameCache.get(cacheKey);
  if (cached && Date.now() - cached.updatedAt < NAME_CACHE_TTL_MS) {
    return cached.name;
  }
  try {
    const participants = await roomService.listParticipants(roomName);
    if (participantIdentity) {
      const byIdentity = participants.find(
        (p) => p.identity === participantIdentity
      );
      if (byIdentity) {
        const resolved = byIdentity.name || byIdentity.identity || null;
        if (resolved) {
          participantNameCache.set(cacheKey, {
            name: resolved,
            updatedAt: Date.now(),
          });
        }
        return resolved;
      }
    }
    if (trackId) {
      const byTrack = participants.find((p) =>
        (p.tracks ?? []).some(
          (t) =>
            t.sid === trackId ||
            t.trackSid === trackId ||
            t.track_id === trackId ||
            t.trackId === trackId
        )
      );
      if (byTrack) {
        const resolved = byTrack.name || byTrack.identity || null;
        if (resolved) {
          participantNameCache.set(
            `${roomName || ''}::${byTrack.identity || ''}`,
            { name: resolved, updatedAt: Date.now() }
          );
        }
        return resolved;
      }
    }
  } catch (err) {
    process.stderr.write(
      `[records] failed to resolve participant name: ${err}\n`
    );
  }
  return null;
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

    const roomName = event?.room?.name;
    if (event?.event === 'room_started') {
      const startedAt =
        toDateFromTimestamp(event?.room?.startedAt) ||
        toDateFromTimestamp(event?.room?.createdAt) ||
        toDateFromTimestamp(event?.room?.creationTime) ||
        toDateFromTimestamp(event?.timestamp) ||
        new Date();
      trackRoomStart(roomName, startedAt);
      return json(res, 200, { ok: true });
    }

    if (event?.event !== 'track_published') {
      return json(res, 200, { ok: true });
    }

    const track = event?.track;
    const trackId = track?.sid;
    const trackType = normalizeTrackType(track?.type);
    if (typeof roomName !== 'string' || roomName.length === 0) {
      return json(res, 400, { error: 'bad_request' });
    }
    if (!isRecordingRoomAllowed(roomName)) {
      return json(res, 200, { ok: true, skipped: true });
    }
    if (typeof trackId !== 'string' || trackId.length === 0) {
      return json(res, 400, { error: 'bad_request' });
    }
    if (trackType !== 'audio') {
      return json(res, 200, { ok: true });
    }

    const now = new Date();
    const roomStartEntry = roomStartTimes.get(roomName);
    const meetingStart =
      roomStartEntry?.startedAt ||
      toDateFromTimestamp(event?.room?.startedAt) ||
      toDateFromTimestamp(event?.room?.createdAt) ||
      toDateFromTimestamp(event?.room?.creationTime) ||
      now;
    const trackStart =
      toDateFromTimestamp(track?.startedAt) ||
      toDateFromTimestamp(track?.publishedAt) ||
      toDateFromTimestamp(event?.timestamp) ||
      now;

    const meetingDate = formatDateLocal(meetingStart);
    const meetingTime = formatTimeLocal(meetingStart);
    const trackTime = formatTimeLocal(trackStart);
    const participantIdentity = event?.participant?.identity ?? null;
    let participantName =
      (typeof event?.participant?.name === 'string' &&
        event.participant.name) ||
      null;
    if (!participantName) {
      participantName = await resolveParticipantName(
        roomName,
        participantIdentity,
        trackId
      );
    }
    if (!participantName) {
      participantName = participantIdentity || 'unknown';
    }

    const started = spawnStart(
      roomName,
      trackId,
      meetingDate,
      meetingTime,
      trackTime,
      participantName
    );

    await appendRecord({
      room: {
        name: roomName,
      },
      participant: {
        name: participantName,
      },
      track: {
        sid: trackId,
      },
      meeting_started_at: meetingStart.toISOString(),
      track_started_at: trackStart.toISOString(),
    });

    return json(res, 200, {
      ok: true,
      started,
    });
  } catch {
    return json(res, 500, { error: 'internal_server_error' });
  }
});

server.listen(8080, '0.0.0.0');
