fs = require 'fs'
{ extname, basename } = require 'path'

books = (basename(f, '.json') for f in fs.readdirSync './converted' when extname(f) is '.json')
console.log books
