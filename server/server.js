import express from 'express'
import path from 'path'
import { Client } from 'pg'
import config from './config'

const app = express()
const PORT = 3000
const client = new Client(config.db)

const res = client
  .connect()
  .then((success) => {
    console.log(success, 'value')
  })
  .catch((err) => {
    console.log('Could not connect')
    console.log(err)
  })
console.log(res)

app.get('/test', (req, res) => {
  res.send('Express + TypeScript')
})

app.use('/', express.static('public'))

app.listen(PORT, () => {
  console.log(`⚡️[server]: Server is running at https://localhost:${PORT}`)
})
