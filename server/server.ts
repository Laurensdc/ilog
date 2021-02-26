import express from 'express'
import path from 'path'
const app = express()
const PORT = 3000

app.get('/test', (req, res) => {
  res.send('Express + TypeScript')
})

app.use('/', express.static('public'))

app.listen(PORT, () => {
  console.log(`⚡️[server]: Server is running at https://localhost:${PORT}`)
})
