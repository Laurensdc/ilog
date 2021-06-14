const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const open = require('open');
const path = require('path');

const app = express();
// app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

app.use(cors());
app.options('*', cors());

const PORT = 3000;

app.get('/test', (req, res) => {
  res.send('Express + TypeScript');
});

app.use(express.static(path.join(__dirname, 'public')));

app.use('/calls', require('./routes/calls'));
app.use('/subtasks', require('./routes/subtasks'));

app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);

  // open(`http://localhost:${PORT}`);
});
