const h = require('../helpers');

const callSeed = `
INSERT INTO
  calls(who, comments, created_at)
VALUES
  ('Jan van Carrefour', 'Blabla hier is veel tekst van mij', NOW()),
  ('Gerard van de Begonia''s', 'Amai wat is Gerard een irritante zak zeg!', NOW()),
  ('Hans', 'Nog wat dingen herbekijken straks peisk', NOW())
;
`;

const subtasksSeed = `
INSERT INTO
  subtasks(call_id, text, done)
VALUES
  (1, 'Bellen', FALSE),
  (1, 'Taak toevoegen aan CRM', FALSE),
  (2, 'Hans vragen hoe dat zit met die dinges', FALSE),
  (2, 'Ook eens checken hoe het zit met die dattes', FALSE),
  (2, 'Ahja dit is al klaar', TRUE),
  (3, 'Pizza bestellen', FALSE)
`;

module.exports = h.db
  .query(callSeed)
  .then(() => {
    return h.db.query(subtasksSeed);
  })
  .then(() => {
    h.print.colored('Succesfully seeded calls & subtasks\n', 'green');
  })
  .catch((err) => h.print.err(err))
  .finally(() => process.exit(0));
