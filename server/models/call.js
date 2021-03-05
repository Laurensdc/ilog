const { Sequelize, DataTypes } = require('sequelize');
const sequelize = require('../dbconn');

module.exports = sequelize.define(
  'call',
  {
    who: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    comments: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    isArchived: {
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
