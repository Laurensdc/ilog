const db = require('../db');

const resetdb = `
DROP TABLE IF EXISTS calls;
`;

db.query(resetdb, null)
  .then((res) => {
    db.printRows(res.rows);
  })
  .catch((err) => db.printErr(err))
  .finally(() => process.exit(0));
