# ilog

## Build & run

- Prerequisites:
  [Git](https://git-scm.com/download/win), [Node.js](https://nodejs.org/en/download/), [PostgreSQL](https://www.postgresql.org/download/) and [Elm](https://guide.elm-lang.org/install/elm.html)

- Create your PostgreSQL database.
- `cd server && cp config-example.js config.js` and add your db login credentials.

`./run` or open `run-win.bat` on Windows to run the app.

Builds & minifies Elm , serves Node backend and opens browser with Frontend app.

---

## Dev

- `./dev`  
  Run & live reload with `elm-live` on `http://localhost:8000`,  
  Run & live reload backend files on `http://localhost:3000` with `nodemon`.

### Elm @Frontend

#### Dependencies

- Node.js
- Install [Elm](https://guide.elm-lang.org/install/).  
  [Editor plugins](https://github.com/elm/editor-plugins) are highly recommended.
- Best to `npm install -g elm-test elm-format` for.. testing and autoformatting.

### Node.js @Backend

Node.js/Express app with PostgreSQL.  
Stuff below happens in `/server` directory.

- `cp config.example.js config.js` and add with your settings

Commands:

- `npm run dev`  
  Run & live reload with `nodemon`

- `npm run prod` (Windows)  
  Run Node.js backend, serve frontend and open browser

- `npm run resetdb`

  > **_WARNING_** You will lose all data!

  Wipes the whole database and recreates it.
