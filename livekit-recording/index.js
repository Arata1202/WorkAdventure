const express = require('express');
const cors = require('cors');
const { EgressClient, EncodedFileType } = require('livekit-server-sdk');

const app = express();
app.use(cors());
app.use(express.json());

const config = {
  livekitUrl: process.env.LIVEKIT_URL || '',
  apiKey: process.env.LIVEKIT_API_KEY || '',
  apiSecret: process.env.LIVEKIT_API_SECRET || '',
  minioEndpoint: process.env.MINIO_ENDPOINT || '',
  minioAccessKey: process.env.MINIO_ACCESS_KEY || '',
  minioSecretKey: process.env.MINIO_SECRET_KEY || '',
  minioRegion: process.env.MINIO_REGION || 'us-east-1',
  port: parseInt(process.env.PORT || '8080', 10),
};

// 録画開始
app.post('/api/recording/start', async (req, res) => {
  try {
    const { room_name, filename } = req.body;
    console.log(`Starting recording: ${room_name} -> ${filename}`);

    const egressClient = new EgressClient(config.livekitUrl, config.apiKey, config.apiSecret);

    const info = await egressClient.startRoomCompositeEgress(room_name, {
      layout: 'grid',
      audioOnly: false,
      videoOnly: false,
      fileOutputs: [{
        fileType: EncodedFileType.MP4,
        filepath: filename,
        s3: {
          accessKey: config.minioAccessKey,
          secret: config.minioSecretKey,
          endpoint: config.minioEndpoint,
          bucket: 'livekit-recording',
          region: config.minioRegion,
          forcePathStyle: true,
        },
      }],
    });

    console.log(`Recording started: ${info.egressId}`);
    res.json({ success: true, egress_id: info.egressId, message: 'Recording started' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 録画停止
app.post('/api/recording/stop', async (req, res) => {
  try {
    const { egress_id } = req.body;
    console.log(`Stopping recording: ${egress_id}`);

    const egressClient = new EgressClient(config.livekitUrl, config.apiKey, config.apiSecret);
    const info = await egressClient.stopEgress(egress_id);

    console.log(`Recording stopped: ${info.egressId}`);
    res.json({ success: true, egress_id: info.egressId, message: 'Recording stopped' });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(config.port, () => {
  console.log(`Recording API running on port ${config.port}`);
});
