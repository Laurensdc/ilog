const express = require('express');
const h = require('../helpers');
const router = express.Router();

/**
 * Returns call with included subtasks
 */
router.get('/', async function (req, res) {
  const callsSql = `
    SELECT * FROM calls
  `;

  const subTasksSql = `
    SELECT * FROM subtasks
  `;

  try {
    const callsSqlResult = await h.db.query(callsSql);
    const calls = h.db.sqlToArr(callsSqlResult);

    const subTasksSqlResult = await h.db.query(subTasksSql);
    const subTasks = h.db.sqlToArr(subTasksSqlResult);

    return res.status(200).json({
      message: 'message',
      calls,
      subTasks,
    });
  } catch (err) {
    h.print.err(err);
    return res.status(400).json({
      message: 'Something went wrong',
      error: err,
    });
  }
});

module.exports = router;
