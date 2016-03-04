path = require 'path'

cwd = process.cwd()
module.exports =
  entry:path.join cwd, 'assets/scripts/main.coffee'
  output:
    path: cwd
    filename: 'bundle.js'
  module:
    loaders:[
      {test: /\.coffee$/, loader: "coffee"}
    ]
