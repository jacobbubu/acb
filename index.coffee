# http://magnetiq.com/pages/acb-spec/

fs = require 'fs'
path = require 'path'
decoder = require './decoder'
{ getBasename } = require './utils'

src = './color-books'
dest = './converted'
files = fs.readdirSync src

for f in files
    ext = path.extname f
    if ext is '.acb'
        basename = getBasename(f)
        { decode } = decoder fs.readFileSync(path.join src, f)
        try
            fs.writeFileSync path.join(dest, basename + '.json'), JSON.stringify(decode(), null, 2), 'utf8'
        catch err
            console.error "Errors in #{basename}", err, f
