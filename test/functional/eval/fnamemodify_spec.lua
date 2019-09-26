local helpers = require('test.functional.helpers')(after_each)
local clear = helpers.clear
local eq = helpers.eq
local iswin = helpers.iswin
local fnamemodify = helpers.funcs.fnamemodify
local command = helpers.command
local write_file = helpers.write_file

-- see unit tests for fnamemodify() tests that don't use cwd

describe('fnamemodify()', function()
  setup(function()
    write_file('Xtest-fnamemodify.txt', [[foobar]])
  end)

  before_each(clear)

  teardown(function()
    os.remove('Xtest-fnamemodify.txt')
  end)

  it('handles the root path', function()
    local root = helpers.pathroot()
    eq(root, fnamemodify([[/]], ':p:h'))
    eq(root, fnamemodify([[/]], ':p'))
    if iswin() then
      eq(root, fnamemodify([[\]], ':p:h'))
      eq(root, fnamemodify([[\]], ':p'))
      command('set shellslash')
      root = string.sub(root, 1, -2)..'/'
      eq(root, fnamemodify([[\]], ':p:h'))
      eq(root, fnamemodify([[\]], ':p'))
      eq(root, fnamemodify([[/]], ':p:h'))
      eq(root, fnamemodify([[/]], ':p'))
    end
  end)

  it(':8 works', function()
    eq('Xtest-fnamemodify.txt', fnamemodify([[Xtest-fnamemodify.txt]], ':8'))
  end)

  describe('examples from ":help filename-modifiers"', function()
    local filename = "src/version.c"
    local cwd = helpers.getcwd()

    it(':p', function()
      eq(cwd .. '/src/version.c', fnamemodify(filename, ':p'))
    end)

    it(':p:.', function()
      eq('src/version.c', fnamemodify(filename, ':p:.'))
    end)

    it(':p:h', function()
      eq(cwd .. '/src', fnamemodify(filename, ':p:h'))
    end)

    it(':p:h:h', function()
      eq(cwd .. '', fnamemodify(filename, ':p:h:h'))
    end)

    it(':p:t', function()
      eq('version.c', fnamemodify(filename, ':p:t'))
    end)

    it(':p:r', function()
      eq(cwd .. '/src/version', fnamemodify(filename, ':p:r'))
    end)

    it(':s?version?main?:p', function()
      eq(cwd .. '/src/main.c', fnamemodify(filename, ':s?version?main?:p'))
    end)

    it(':p:gs?/?\\\\?', function()
      local converted_cwd = cwd:gsub('/', '\\')
      eq(converted_cwd .. '\\src\\version.c', fnamemodify(filename, ':p:gs?/?\\\\?'))
    end)
  end)
end)
