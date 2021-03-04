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
 * @param {object} call - {
 *  who: String,
 *  comments: String,
 *  when: Number (millisFromPosix),
 *
 *  subTasks?: {
 *    text: String,
 *    done?: Bool
 *  }
 * }
 */
router.put('/add', async (req, res) => {
  const call = req.body.call;

  /** Validation **/
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

  /** Inserting **/
  try {
    const insertCallSQL = `
    INSERT INTO calls (who, comments, created_at, is_archived)
      VALUES ($1, $2, $3, FALSE)
      RETURNING id;
    `;

    const callResult = await h.db.query(insertCallSQL, [
      call.who,
      call.comments,
      new Date(call.when),
    ]);

    const callId = h.db.sqlToArr(callResult)[0].id;

    const subTasks = getParsedSubTasks(callId, call.subTasks);
    const prepSubtaskInserts = h.db.prepareInserts(subTasks);

    let insertSubTasksSQL = `
    INSERT INTO subtasks (call_id, text, done)
      VALUES 
  ${prepSubtaskInserts.values}
    ;     
    `;

    await h.db.query(insertSubTasksSQL, prepSubtaskInserts.params);

    return res.status(200).json({
      message: 'Added call to DB',
      callId,
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
 * Returns array of type checked & parsed subtasks
 * @param {object[]} subTasks
 */
function getParsedSubTasks(callId, subTasks) {
  if (subTasks && Array.isArray(subTasks)) {
    return subTasks
      .map((st) => {
        // subTasks.text is present?
        if ('text' in st) {
          const text = String(st.text);

          // subTasks.done is present & is bool?
          if ('done' in st && typeof st.done === 'boolean') {
            return {
              call_id: callId,
              text,
              done: st.done,
            };
          } else {
            return {
              call_id: callId,
              text,
              done: false,
            };
          }
        }
      })
      .filter((st) => st !== null && st !== undefined);
  } else return [];
}

module.exports = router;
