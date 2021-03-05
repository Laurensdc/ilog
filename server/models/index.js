const { Sequelize, DataTypes } = require('sequelize');
const sequelize = require('../dbconn');

const Call = require('./call');
const SubTask = require('./subtask');

Call.hasMany(SubTask);

module.exports = {
  Call,
  SubTask,
};
