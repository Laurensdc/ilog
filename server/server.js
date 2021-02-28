const express = require('express');
const bodyParser = require('body-parser');

const app = express();
// app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

const PORT = 3000;

app.get('/test', (req, res) => {
  res.send('Express + TypeScript');
});

app.use('/', express.static('public'));

app.use('/calls', require('./routes/calls'));

app.listen(PORT, () => {
  console.log(`⚡️[server]: Server is running at https://localhost:${PORT}`);
});
