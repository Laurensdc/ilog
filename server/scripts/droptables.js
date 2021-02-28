const h = require('../helpers');

const dropSubtasks = `
DROP TABLE IF EXISTS subtasks;
`;

const dropCalls = `
DROP TABLE IF EXISTS calls;
`;

module.exports = h.db
  .query(dropSubtasks)
  .then((res) => {
    h.print.colored('Subtasks table deleted', 'green');
    return h.db.query(dropCalls);
  })
  .then(() => {
    h.print.colored('Calls table deleted', 'green');
  })

  .catch((err) => h.print.err(err))
  .finally(() => process.exit(0));
