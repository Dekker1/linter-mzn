module.exports =
  config:
    compilerPath:
      type: 'string'
      default: 'mzn2fzn'
      description: 'Path to Minizinc\'s compiler `mzn2fzn`'

  activate: (state) ->
    require('atom-package-deps').install 'linter-mzn'

  provideLinter: ->
    LinterMZN = require('./linter-mzn')
    @provider = new LinterMZN()
    return {
      name: 'MiniZinc',
      grammarScopes: ['source.mzn'],
      scope: 'file',
      lintsOnChange: false,
      lint: @provider.lint
    }
