const h = require('../helpers');

const createCallsTableSQL = `
CREATE TABLE IF NOT EXISTS calls (
	id            SERIAL                PRIMARY KEY,
	who           VARCHAR (100),
	comments      TEXT,
	created_at    TIMESTAMP             DEFAULT NOW(),
  is_archived   BOOLEAN               DEFAULT false
);
`;

const createSubTasksTableSQL = `
CREATE TABLE IF NOT EXISTS subtasks (
  id            SERIAL                PRIMARY KEY,
  call_id       INT                   REFERENCES calls(id)      ON DELETE CASCADE,
  text          VARCHAR (255),
  done          BOOLEAN               DEFAULT false
)
`;

module.exports = h.db
  .query(createCallsTableSQL, null)

  .then(() => {
    return h.db.query(createSubTasksTableSQL, null);
  })
  .then(() => {
    h.print.colored('Succesfully created tables calls & subtasks\n', 'green');
  })
  .catch((err) => db.printErr(err))
  .finally(() => process.exit(0));
