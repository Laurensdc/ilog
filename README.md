# ilog

## Build & run

`./run`  
Using the thing.

Builds Elm, builds Node.js TS to JS, serves Node backend and opens browser with Frontend app.

---

## Dev

### Elm @Frontend

#### Scripts

- `./dev`  
  Run & live reload with `elm-live`

#### Dependencies

- Node.js
- Install [Elm](https://guide.elm-lang.org/install/).  
  [Editor plugins](https://github.com/elm/editor-plugins) are highly recommended.
- Best to `npm install -g elm-test elm-format` as well, for.. testing and autoformatting.

### Node.js @Backend

Node.js/Express app with TypeScript.  
Stuff below happens in `/server` directory.

- `npm run dev`  
  Run & live reload with `ts-node-dev`

- `tsc`  
  Build. Output in `/build`

---
