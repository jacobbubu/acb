path = require 'path'

getBasename = (file) ->
    ext = path.extname file
    path.basename file, ext

module.exports = { getBasename }
