color = require 'cli-color'

{ extendedTypeOf } = require './util'

Theme =
  ' ': (s) -> s
  '+': color.green
  '-': color.red


subcolorizeToCallback = (key, diff, output, color, indent, mark) ->
  prefix    = if key then "#{key}: " else ''
  mark = if mark then mark else ''
  subindent = indent + '  '
  tag = if mark.length > 0 then '/' + mark else ''

  switch extendedTypeOf(diff)
    when 'object'
      if ('__old' of diff) and ('__new' of diff)
        if (Object.keys(diff).length is 2)
          subcolorizeToCallback(key, diff.__old, output, '-', indent)
          subcolorizeToCallback(key, diff.__new, output, '+', indent)
        else if (Object.keys(diff).length is 3 and '__old' of diff is true)
          subcolorizeToCallback(key, diff.__old, output, '-', indent, 't')
          subcolorizeToCallback(key, diff.__new, output, '+', indent, 't')
      else
        output color, tag + "#{indent}#{prefix}{"
        for own subkey, subvalue of diff
          if m = subkey.match /^(.*)__deleted$/
            subcolorizeToCallback(m[1], subvalue, output, '-', subindent)
          else if m = subkey.match /^(.*)__added$/
            subcolorizeToCallback(m[1], subvalue, output, '+', subindent)
          else
            subcolorizeToCallback(subkey, subvalue, output, color, subindent)
        output color, tag + "#{indent}}"

    when 'array'
      output color, tag + "#{indent}#{prefix}["

      looksLikeDiff = yes
      for item in diff
        if (extendedTypeOf(item) isnt 'array') or !((item.length is 2) or ((item.length is 1) and (item[0] is ' '))) or !(typeof(item[0]) is 'string') or item[0].length != 1 or !(item[0] in [' ', '-', '+', '~'])
          looksLikeDiff = no

      if looksLikeDiff
        for [op, subvalue] in diff
          if op is ' ' && !subvalue?
            output(' ', subindent + '...')
          else
            unless op in [' ', '~', '+', '-']
              throw new Error("Unexpected op '#{op}' in #{JSON.stringify(diff, null, 2)}")
            op = ' ' if op is '~'
            subcolorizeToCallback('', subvalue, output, op, subindent)
      else
        for subvalue in diff
          subcolorizeToCallback('', subvalue, output, color, subindent)

      output color, "#{indent}]"

    else
      if diff == 0 or diff == null or diff == false or diff
        output(color, tag + indent + prefix + JSON.stringify(diff))



colorizeToCallback = (diff, output) ->
  subcolorizeToCallback('', diff, output, ' ', '')


colorizeToArray = (diff) ->
  output = []
  colorizeToCallback(diff, (color, line) -> output.push "#{color}#{line}")
  return output


colorize = (diff, options={}) ->
  output = []
  colorizeToCallback diff, (color, line) ->
    if options.color ? yes
      output.push (options.theme?[color] ? Theme[color])("#{color}#{line}") + "\n"
    else
      output.push "#{color}#{line}\n"
  return output.join('')


module.exports = { colorize, colorizeToArray, colorizeToCallback }
