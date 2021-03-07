const express = require('express');
const { db } = require('../config');
const h = require('../helpers');
const router = express.Router();
const { Call, SubTask } = require('../models');

/**
 * Returns call with included subtasks
 */
router.get('/', async (req, res) => {
  try {
    const calls = await Call.findAll({ order: [['updatedAt', 'DESC']] });
    const subTasks = await SubTask.findAll({ order: [['updatedAt', 'DESC']] });

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

  if (!validateCall(call)) {
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
      isArchived: false,
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
 * Update call.who && call.comments
 */
router.post('/:id/edit', async (req, res) => {
  const id = req.params.id;
  const newCall = req.body.call;
  const newSubTasks = req.body.subTasks;

  if (!id) {
    return res.status(400).json({
      message: 'Please pass a callId',
    });
  }

  const call = await Call.findByPk(id);
  if (!call) {
    return res.status(400).json({
      message: `Call with id ${id} not found`,
    });
  }

  if (
    !(
      'who' in call &&
      typeof call.who === 'string' &&
      'comments' in call &&
      typeof call.comments === 'string'
    )
  ) {
    if (!validateCall(call)) {
      return res.status(400).json({
        message: 'Incorrectly formed call in body, expecting { who: String, comments: String }',
        call: null,
      });
    }
  }

  const subTasks = getParsedSubTasks(id, newSubTasks);
  const updatedSubTasks = [];

  try {
    if (subTasks.length > 0) {
      for (let i = 0; i < subTasks.length; i++) {
        h.print.colored('Updating subtask ' + subTasks[i].id, 'yellow');

        const dbSubTask = await SubTask.findByPk(subTasks[i].id);

        if (dbSubTask) {
          dbSubTask.text = subTasks[i].text;
          dbSubTask.done = subTasks[i].done;
          await dbSubTask.save();
          updatedSubTasks.push(dbSubTask);
        }
      }
    }

    // TODO Delete subTasks that aren't passed here but belong to call !
    // E.g. call has subtasks with id 1, 2, 3
    // but here only subTasks[] with id 2, 3 are passed
    // -> Delete subTask with id 1

    // TODO Add subTasks that didn't exist yet!

    call.comments = newCall.comments;
    call.who = newCall.who;
    await call.save();

    return res.status(200).json({
      message: 'Call updated',
      call,
      subTasks: updatedSubTasks,
    });
  } catch (err) {
    h.print.colored('ERROR' + err, 'red');
  }
});

/**
 * Toggle "isArchived" for this subTask
 */
router.get('/:id/archive', async (req, res) => {
  try {
    const id = req.params.id;
    if (!id) {
      return res.status(400).json({
        message: 'Please pass a CallId',
      });
    }

    const call = await Call.findByPk(id);

    if (!call) {
      return res.status(400).json({
        message: 'Call with id ' + id + ' not found',
      });
    }
    call.isArchived = !call.isArchived;
    await call.save();

    return res.status(200).json({
      message: 'Call saved',
      updatedCall: call,
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
              id: st.id,
              callId: callId,
              text,
              done: st.done,
            };
          } else {
            return {
              id: st.id,
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

function validateCall(call) {
  return (
    'who' in call &&
    typeof call.who === 'string' &&
    'comments' in call &&
    typeof call.comments === 'string' &&
    'when' in call &&
    typeof call.when === 'number'
  );
}

module.exports = router;
