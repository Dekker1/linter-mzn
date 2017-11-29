{BufferedProcess} = require 'atom'
{CompositeDisposable} = require 'atom'

atomLinter = require 'atom-linter'

class LinterMZN

  constructor: ->
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.config.observe 'linter-mzn.compilerPath',
    (compilerPath) =>
      @compilerPath = compilerPath

  lint: (textEditor) =>
    command = @compilerPath
    args = ['--instance-check-only', textEditor.getPath()]
    options =
      timeout: 10000
      env: process.env
      stream: 'both'

    atomLinter.exec(@compilerPath, args, options)
      .then (result) =>
        {stdout, stderr, exit} = result
        console.log stderr
        if exit is 0
          []
        else
          @parse stderr
      .catch (error) ->
        console.log error
        atom.notifications.addError "Failed to run #{command}",
          detail: "#{error.message}"
          dismissable: true
        []

  parse: (output) =>
    messages = []
    output = output.split('\n')
    warningLines = (i for line, i in output when /:([0-9]+):/.test(line) && ! /(did you forget to specify a data file\?)/.test(output[i+1]))

    i = 0
    while i < warningLines.length
      if i >= warningLines.length - 1
        messages.push @generateMessage output[warningLines[i]..]
      else
        messages.push @generateMessage output[warningLines[i]..warningLines[i+1]-1]
      i++

    return messages

  generateMessage: (output) ->
    file = output[0].match(/^[^:]*/)[0]
    console.log file
    match = output[0].match(/:([0-9]+):/)
    line = parseInt(match[1])
    output = output[1..]

    startcol = 0
    endcol = 500;
    if output.length > 1 and /\^/.test(output[1])
      startcol = output[1].match(/\^/).index
      endcol = output[1].match(/\^(\s|$)/).index + 1
      output = output[2..]

    message = {
      severity: 'error',
      excerpt: output.join('\n').replace(/MiniZinc: /, "").replace(/Error: /, ""),
      location:{
        file: file,
        position: [[line-1,startcol], [line-1,endcol]],
      }
    }

    return message


module.exports = LinterMZN
