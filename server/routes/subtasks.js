const express = require('express');
const h = require('../helpers');
const router = express.Router();
const { Call, SubTask } = require('../models');

/**
 * Toggle "done" for this subTask
 */
router.get('/:id/done', async (req, res) => {
  try {
    const id = req.params.id;
    if (!id) {
      return res.status(400).json({
        message: 'Please pass a subTask ID',
      });
    }

    const subTask = await SubTask.findByPk(id);

    if (!subTask) {
      return res.status(400).json({
        message: 'SubTask with id ' + id + ' not found',
      });
    }
    subTask.done = !subTask.done;
    await subTask.save();

    return res.status(200).json({
      message: 'SubTask saved',
      updatedSubTask: subTask,
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
