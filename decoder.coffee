{ getBasename } = require './utils'

decoder = (buf) ->
    offset = 0

    readBytes = (count) ->
        end = Math.min offset + count, buf.length
        v = buf.slice offset, end
        offset = end
        v

    readChars = (count = 1) -> readBytes(count).toString('ascii')

    readUInt16 = -> offset += 2; v = buf.readUInt16BE(offset-2)

    readUInt32 = -> offset += 4; v = buf.readUInt32BE(offset-4)

    readString = ->
        length = readUInt32()
        v = ''
        for i in [0...length]
            v += String.fromCharCode(readUInt16())
        v

    extractValue = (str) ->
        # remove wrapper double quote
        value = str.replace /^"(.*)"$/, '$1'

        # e.x: $$$/acb/Pantone/ProcessYellow=Process Yellow CP
        if value.startsWith '$$$'
            value = value.split('=')[1]

        value = value.replace '^R', '®'
        value = value.replace '^C', '©'
        value

    ColorSpace = (c) ->
        switch c
            when 0 then 'RGB'
            when 1 then 'HSB'
            when 2 then 'CMYK'
            when 3 then 'Pantone'
            when 4 then 'Focoltone'
            when 5 then 'Trumatch'
            when 6 then 'Toyo'
            when 7 then 'LAB'
            when 8 then 'Grayscale'
            when 10 then 'HKS'
            else
                throw new Error "Unknown color space value (#{c})"

    SpotProcessIdentifier = (v) ->
        switch v
            when 'spflspot' then 'Spot'
            when 'spflproc' then 'Process'
            else
                new Error "Unknown Spot/Process Identifier(#{v})"

    decode = ->
        if readChars(4) isnt '8BCB'
            throw new Error 'Invalid .acb data'
        version = readUInt16()
        identifier = readUInt16()
        title = extractValue readString()

        prefix = extractValue readString()
        suffix = extractValue readString()
        trimmed = suffix.trim()
        description = extractValue readString()
        colorCount = readUInt16()
        pageSize = readUInt16()
        pageSelectorOffset = readUInt16()
        colorSpace = ColorSpace readUInt16()
        channels = switch colorSpace
            when 'CMYK' then 4
            when 'Grayscale' then 1
            else 3
        records = {}

        for i in [0...colorCount]
            colorName = extractValue readString()
            colorCode = readChars(6).trim()
            colorCode = colorCode.replace /^0*(\d+)$/ , '$1'
            colorCode = colorCode.replace 'X', '-'
            raw = readBytes channels

            # Skip dummy record
            if !colorName and !colorCode
                continue

            if !colorName
                tail = suffix.trim()
                pos = colorCode.lastIndexOf trimmed
                colorName = if pos >= 0 then colorCode[0...pos] else colorCode

            record =
                name: prefix + colorName + suffix
                code: colorCode

            record.components = switch colorSpace
                when 'LAB'
                    record.components = [
                        raw[0] / 2.55            # 0% thru 100%
                        raw[1] - 128             # -128 thru 127
                        raw[2] - 128             # -128 thru 127
                    ]
                when 'CMYK'
                    record.components = [
                        (255 - raw[0]) / 2.55    # 0% thru 100%
                        (255 - raw[1]) / 2.55    # 0% thru 100%
                        (255 - raw[2]) / 2.55    # 0% thru 100%
                        (255 - raw[3]) / 2.55    # 0% thru 100%
                    ]
                when 'RGB'
                    record.components = [ raw[0], raw[1], raw[2] ]

            records[record.name] = record

        spotIdentifier = SpotProcessIdentifier readChars(8)

        realColorCount = Object.keys(records).length
        {
            version, title, description, prefix, suffix, colorCount: realColorCount, pageSize
            colorSpace, channels,
            isSpot: spotIdentifier is 'Spot',
            records
        }

    return { decode}

module.exports = decoder
