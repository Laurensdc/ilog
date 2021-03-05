const { Sequelize } = require('sequelize');
const config = require('./config');

const sequelize = new Sequelize(config.db.database, config.db.user, config.db.password, {
  dialect: 'postgres',

  host: 'localhost',
  port: config.db.port,
});

module.exports = sequelize;
