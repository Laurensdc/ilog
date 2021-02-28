const express = require('express');
const h = require('../helpers');
const router = express.Router();

/**
 * Returns call with included subtasks
 */
router.get('/', async (req, res) => {
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

/**
 * Adds call to db
 * @param {object} call - { who: String, comments: String, when: Number (millisFromPosix) }
 */
router.put('/add', async (req, res) => {
  const call = req.body.call;
  console.log(req.body);

  if (!call) {
    return res.status(400).json({
      message: 'Please submit a call object with this request',
      call: null,
    });
  }

  if (
    !(
      'who' in call &&
      typeof call.who === 'string' &&
      'comments' in call &&
      typeof call.comments === 'string' &&
      'when' in call &&
      typeof call.when === 'number'
    )
  ) {
    return res.status(400).json({
      message:
        'Incorrectly formed call in body, expecting { who: String, comments: String, when: Number (millisFromPosix) }',
      call: null,
    });
  }

  try {
    const sql = `
    INSERT INTO calls (who, comments, created_at, is_archived)
      VALUES ($1, $2, $3, FALSE);
    `;

    await h.db.query(sql, [call.who, call.comments, new Date(call.when)]);

    return res.status(200).json({
      message: 'Added call to DB',
      call,
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
