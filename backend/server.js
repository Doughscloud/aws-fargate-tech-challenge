const express = require('express');
const cors = require('cors');
const { port, host, corsAllowedOrigin } = require('./config');

const app = express();
app.use(cors({ origin: corsAllowedOrigin }));

app.get('/health', (req, res) => res.status(200).send('OK'));
app.get('/', (req, res) => {
  const guid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
  res.json({ message: 'SUCCESS', guid });
});

app.listen(port, host, () => {
  console.log(`Backend listening on http://${host}:${port} CORS=${corsAllowedOrigin}`);
});
