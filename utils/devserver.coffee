#!/usr/bin/env coffee
express     = require 'express'
path        = require 'path'
webpack     = require 'webpack'
Server      = require 'webpack-dev-server'
_           = require 'lodash'

app = express()

app.set 'view engine', 'jade'
app.set 'views', path.join __dirname, '../assets/templates'

app.get '/', (req, res)->
  res.render 'base', {}

app.listen 8888, ->
  console.log 'Start'
  compiler = webpack require('../webpack.config.js')
  server = new Server compiler
  server.listen 8080
  

