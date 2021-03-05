const express = require('express');
const h = require('../helpers');
const router = express.Router();
const { Call, SubTask } = require('../models');

/**
 * Returns call with included subtasks
 */
router.get('/', async (req, res) => {
  try {
    const calls = await Call.findAll();
    const subTasks = await SubTask.findAll();

    return res.status(200).json({
      message: 'Retrieved all calls & subTasks',
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
    const dbCall = await Call.create({
      who: call.who,
      comments: call.comments,
      when: new Date(call.when),
    });
    const callId = dbCall.id;

    const subTasks = getParsedSubTasks(callId, call.subTasks);

    h.print.colored('subtasks', 'magenta');
    h.print.colored(call.subTasks, 'magenta');
    const dbSubTasks = await SubTask.bulkCreate(subTasks);

    return res.status(200).json({
      message: 'Added call to DB',
      call: dbCall,
      subTasks: dbSubTasks,
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
              callId: callId,
              text,
              done: st.done,
            };
          } else {
            return {
              callId: callId,
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
