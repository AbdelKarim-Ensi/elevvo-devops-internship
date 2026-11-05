const express = require('express');
const { MongoClient } = require('mongodb');

const app = express();
const client = new MongoClient(process.env.MONGO_URL);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.get('/', async (_req, res) => {
  try {
    await client.connect();
    const visits = client.db('app').collection('visits');
    await visits.insertOne({ at: new Date() });
    res.json({ message: 'Hello from Elevvo (Docker + MongoDB)', visits: await visits.countDocuments() });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.listen(3000, '0.0.0.0', () => console.log('API listening on 3000'));
