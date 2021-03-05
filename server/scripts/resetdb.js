const models = require('../models'); // Require all models so sequelize knows them

const sequelize = require('../dbconn');
const h = require('../helpers');

sequelize
  .sync({ force: true })
  .then(() => {
    h.print.colored('DB reset', 'green');
  })
  .catch((err) => {
    h.print.colored('Error!', 'red');
    h.print.colored(err, 'red');
  })
  .finally(() => {
    sequelize.close();
  });
