const { Pool } = require('pg');
const config = require('../config');
const h = require('./index');

const pool = new Pool(config.db);

module.exports = {
  /**
   * PostgreSQL helper functions
   */

  /**
   *
   * @param {string} sqlQuery
   * @param {string[]} params
   * @param {(error, result)} callback
   */
  query: (sqlQuery, params, callback) => {
    h.print.colored('Executing query:', 'cyan');
    console.log(sqlQuery);
    return pool.query(sqlQuery, params, callback);
  },

  /**
   * Safely return sqlResult as array
   * @param {object} sqlResult
   * @returns {object[]}
   */
  sqlToArr: (sqlResult) => {
    if (sqlResult && sqlResult.rows && Array.isArray(sqlResult.rows)) return sqlResult.rows;
    else return [];
  },

  /**
   *  Use it like this:
   *
   *  `node-postgres.query('INSERT INTO table (col1, col2, col3)`
   *
   *  `VALUES' + `_values_, _params_`);`
   *
   * @param {object[]} objects - These should all be structured the same!
   *  e.g. ```[{ col1: 'hi', col2: true, col3: 5 }, { col1, 'yes', col2: false, col3: 10 }]```
   *
   * @returns {object} ``` { values: String, params: [] } ```
   */
  prepareInserts: (objects) => {
    if (!Array.isArray(objects) || !(objects.length > 0)) {
      return;
    }

    // the actual string to be inserted in the VALUES ( ... ) query
    let values = '';

    // this counter keeps track of the correct $int to insert
    let valueCounter = 1;

    // Take first object as example for structure
    let objectKeyCount = Object.keys(objects[0]).length;

    for (let i = 0; i < objects.length; i++) {
      // INSERT VALUES ($1, $2), ($3, $4) and so on ...
      values += '(';

      for (let j = 0; j < objectKeyCount; j++) {
        values += '$' + (valueCounter + j);
        if (j < objectKeyCount - 1) values += ', ';
      }

      values += ')';

      // next pair should start at this number
      valueCounter += objectKeyCount;

      // Last one shouldn't have a trailing comma
      if (i < objects.length - 1) values += ',\n';
    }

    // bump everything into one consecutive array
    // ['hi', true, 5, 'yes', false, 10]
    const params = [];
    objects.forEach((a) => {
      for (const key in a) {
        if (a.hasOwnProperty(key)) params.push(a[key]);
      }
    });

    return { values, params };
  },
};
