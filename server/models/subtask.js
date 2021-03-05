const { Sequelize, DataTypes } = require('sequelize');
const sequelize = require('../dbconn');

module.exports = sequelize.define(
  'subTask',
  {
    text: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },

    done: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
      allowNull: false,
    },
  },
  {
    timestamps: true,
    underscored: false,
  }
);
