const h = require('../helpers');

const dropSubtasks = `
DROP TABLE IF EXISTS subtasks;
`;

const dropCalls = `
DROP TABLE IF EXISTS calls;
`;

module.exports = h.db
  .query(dropSubtasks)
  .then(() => {
    return h.db.query(dropCalls);
  })
  .then(() => {
    h.print.colored('Successfully deleted Calls & Subtasks tables\n', 'green');
  })

  .catch((err) => h.print.err(err))
  .finally(() => process.exit(0));
