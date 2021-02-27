const db = require('../db');

const resetdb = `
DROP TABLE IF EXISTS calls;
`;

db.query(resetdb, null, (err, res) => {
  if (err) {
    console.log('Error!');
    console.error(err);
  } else {
    console.log(res.rows[0]);
  }
});

process.exit(0);
