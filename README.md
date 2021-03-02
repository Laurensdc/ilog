# ilog

## Build & run

`./run`  
Using the thing.

Builds Elm, serves Node backend and opens browser with Frontend app.

---

## Dev

- `./dev`  
  Run & live reload with `elm-live` on `http://localhost:8000`,  
  Run & live reload backend files on `http://localhost:3000` with `ts-node-dev`.

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
