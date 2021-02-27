const db = require('../db');

const callSeed = `
INSERT INTO
  calls(id, who, comments, created_at)
VALUES
  (1, 'Jan van Carrefour', 'Blabla hier is veel tekst van mij', NOW()),
  (2, 'Gerard van de Begonia''s', 'Amai wat is Gerard een irritante zak zeg!', NOW()),
  (3, 'Hans', 'Nog wat dingen herbekijken straks peisk', NOW())
;
`;

db.query(callSeed)
  .then((res) => {
    db.printRows(res.rows);
  })
  .catch((err) => db.printErr(err))
  .finally(() => process.exit(0));
