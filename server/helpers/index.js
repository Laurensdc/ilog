const { Pool } = require('pg');
const config = require('../config');

const pool = new Pool(config.db);

module.exports = {
  /**
   * PostgreSQL helper functions
   */
  db: {
    /**
     *
     * @param {string} sqlQuery
     * @param {string[]} params
     * @param {(error, result)} callback
     */
    query: (sqlQuery, params, callback) => {
      module.exports.print.colored('Executing query:', 'cyan');
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
  },

  /**
   * Printing helper functions
   */
  print: {
    /**
     * Node-postgres (SQL) error
     */
    err: (err) => {
      if (err.code || err.detail || err.where) {
        console.log(
          '\x1b[31mSQL Error ' +
            err.code +
            ': ' +
            err.detail +
            (err.where ? ' @' + err.where : '' + '\x1b[33m')
        );
        console.log(err.stack + '\x1b[0m');
        console.log('http://www.google.com/search?q=postgres%20sql%20error%20' + err.code);
      } else {
        console.log('Unknown Error');
        console.log(err);
      }
    },

    /**
     * Result from node-postgres successful SQL statement
     * @param {object} sqlResult
     */
    sqlRows: (sqlResult) => {
      if (
        sqlResult &&
        sqlResult.rows &&
        Array.isArray(sqlResult.rows) &&
        sqlResult.rows.length > 0
      ) {
        sqlResult.rows.forEach((r) => console.log(r));
      } else {
        console.log('No rows returned from sqlResult');
      }
    },

    /**
     * Prints to console in a range of colors
     *
     * @param {string} text - Text to print
     * @param {string} color - Color to print. Valid values are `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `lightgray`, `darkgray`, `black`
     */
    colored: (text, color) => {
      const colorLookup = [
        { colorName: 'red', value: '\x1b[31m' },
        { colorName: 'green', value: '\x1b[32m' },
        { colorName: 'yellow', value: '\x1b[33m' },
        { colorName: 'blue', value: '\x1b[34m' },
        { colorName: 'magenta', value: '\x1b[35m' },
        { colorName: 'cyan', value: '\x1b[36m' },
        { colorName: 'lightgray', value: '\x1b[37m' },
        { colorName: 'darkgray', value: '\x1b[90m' },
        { colorName: 'black', value: '\x1b[30m' },
      ];

      reset = '\x1b[0m';
      colorFound = colorLookup.find((l) => l.colorName === color);

      if (!colorFound) {
        return console.log(
          '\x1b[31mError in printColored().\n' +
            reset +
            'Param color must be one of ' +
            colorLookup.map((c) => c.value + c.colorName + reset) +
            reset +
            '\nReceived value: \x1b[33m' +
            color +
            reset +
            '\n'
        );
      } else {
        return console.log(colorFound.value + text + reset);
      }
    },
  },
};
