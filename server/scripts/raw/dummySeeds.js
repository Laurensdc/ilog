const h = require('../../helpers');

const callSeed = `
INSERT INTO
  calls(who, comments, "createdAt", "updatedAt")
VALUES
  ('Jan van Carrefour', 'Blabla hier is veel tekst van mij', NOW(), NOW()),
  ('Gerard van de Begonia''s', 'Amai wat is Gerard een irritante zak zeg!', NOW(), NOW()),
  ('Hans', 'Nog wat dingen herbekijken straks peisk', NOW(), NOW())
;
`;

const subtasksSeed = `
INSERT INTO
  "subTasks" ("callId", text, done, "createdAt", "updatedAt")
VALUES
  (1, 'Bellen', FALSE, NOW(), NOW()),
  (1, 'Taak toevoegen aan CRM', FALSE, NOW(), NOW()),
  (2, 'Hans vragen hoe dat zit met die dinges', FALSE, NOW(), NOW()),
  (2, 'Ook eens checken hoe het zit met die dattes', FALSE, NOW(), NOW()),
  (2, 'Ahja dit is al klaar', TRUE, NOW(), NOW()),
  (3, 'Pizza bestellen', FALSE, NOW(), NOW())
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
