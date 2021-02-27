const db = require('../db');

const createCallsTableSQL = `
CREATE TABLE IF NOT EXISTS calls (
	id            serial                PRIMARY KEY,
	who           VARCHAR (100),
	comments      TEXT,
	created_at    TIMESTAMP             DEFAULT NOW()
);
`;

const test = `
SELECT NOW() as now`;

db.query(createCallsTableSQL, null)
  .then((res) => {
    console.log('Success.');
    console.log(res.rows[0]);
  })
  .catch((err) => db.printErr(err))
  .finally(() => process.exit(0));
