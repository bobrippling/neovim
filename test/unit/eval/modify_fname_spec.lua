local helpers = require("test.unit.helpers")(after_each)

local itp = helpers.gen_itp(it)
local eq = helpers.eq

local ffi = helpers.ffi
local to_cstr = helpers.to_cstr
local internalize = helpers.internalize

local eval = helpers.cimport("./src/nvim/eval.h")

describe('modify_fname', function()
  local modify_fname = function(fname, mods)
    local mods_cstr = to_cstr(mods)

    local tilde_file = false

    local usedlenp = ffi.typeof("size_t[1]")({ 0 })

    local fname_cstr = to_cstr(fname)
    local fnamep = ffi.typeof("char *[1]")({ fname_cstr })

    local bufp = ffi.typeof("char *[1]")(nil)

    local fnamelen = #fname
    local fnamelenp = ffi.typeof("size_t[1]")({ fnamelen })

    local valid = eval.modify_fname(
      mods_cstr,
      tilde_file,
      usedlenp,
      fnamep,
      bufp,
      fnamelenp)

    local out_mods = ffi.string(mods_cstr)
    local out_fname = ffi.string(fnamep[0], fnamelenp[0])
    -- we must free() out_buf if it's been allocated, whereas mods and fname are already under ffi
    local out_buf = bufp[0] ~= nil and internalize(bufp[0]) or nil

    -- if bufp is set, it's always equal to fnamep (just a handle on the allocation)
    local allocated = false
    if out_buf then
      eq(out_buf, out_fname)
      out_buf = nil
      allocated = true
    end

    return usedlenp[0], out_mods,
      fnamelenp[0], out_fname,
      allocated
  end

  local expect_fully_used_expand = function(fname, modifiers, expected)
    local mods_used, mods, fnamelen, fname, allocated = modify_fname(fname, modifiers)

    eq(modifiers, mods)
    eq(#modifiers, mods_used)

    eq(expected, fname)
    eq(#expected, fnamelen)
  end

  describe('modify with :h', function()
    itp('handles bare filenames', function()
      expect_fully_used_expand('hello.txt', ':h', '.')
    end)

    itp('handles paths', function()
      expect_fully_used_expand('path/to/hello.txt', ':h', 'path/to')
    end)
  end)

  describe('modify with :t', function()
    itp('handles bare filenames', function()
      expect_fully_used_expand('hello.txt', ':t', 'hello.txt')
    end)

    itp('handles paths', function()
      expect_fully_used_expand('path/to/hello.txt', ':t', 'hello.txt')
    end)
  end)

  describe('modify with :r', function()
    itp('handles bare filenames', function()
      expect_fully_used_expand('hello.txt', ':r', 'hello')
    end)

    itp('handles paths', function()
      expect_fully_used_expand('path/to/hello.txt', ':r', 'path/to/hello')
    end)
  end)

  describe('modify with :e', function()
    itp('handles bare filenames', function()
      expect_fully_used_expand('hello.txt', ':e', 'txt')
    end)

    itp('handles paths', function()
      expect_fully_used_expand('path/to/hello.txt', ':e', 'txt')
    end)
  end)

  describe('modify with regex replacements', function()
    itp('handles a simple s///', function()
      expect_fully_used_expand(
        'content-here-here.txt',
        ':s/here/there/',
        'content-there-here.txt')
    end)

    itp('handles global', function()
      expect_fully_used_expand(
        'content-here-here.txt',
        ':gs/here/there/',
        'content-there-there.txt')
    end)
  end)

  itp('modify with shell escape', function()
    expect_fully_used_expand(
      "hello there! quote ' newline\n",
      ':S',
      "'hello there! quote '\\'' newline\n'")
  end)

  describe('simple examples from ":help filename-modifiers"', function()
    local filename = 'src/version.c'

    itp(':h', function()
      expect_fully_used_expand(filename, ':h', 'src')
    end)

    itp(':t', function()
      expect_fully_used_expand(filename, ':t', 'version.c')
    end)

    itp(':r', function()
      expect_fully_used_expand(filename, ':r', 'src/version')
    end)

    itp(':t:r', function()
      expect_fully_used_expand(filename, ':t:r', 'version')
    end)

    itp(':e', function()
      expect_fully_used_expand(filename, ':e', 'c')
    end)

    itp(':s?version?main?', function()
      expect_fully_used_expand(filename, ':s?version?main?', 'src/main.c')
    end)
  end)

  describe('advanced examples from ":help filename-modifiers"', function()
    local filename = "src/version.c.gz"

    itp(':e', function()
      expect_fully_used_expand(filename, ':e', 'gz')
    end)

    itp(':e:e', function()
      expect_fully_used_expand(filename, ':e:e', 'c.gz')
    end)

    itp(':e:e:e', function()
      expect_fully_used_expand(filename, ':e:e:e', 'c.gz')
    end)

    itp(':e:e:r', function()
      expect_fully_used_expand(filename, ':e:e:r', 'c')
    end)

    itp(':r', function()
      expect_fully_used_expand(filename, ':r', 'src/version.c')
    end)

    itp(':r:e', function()
      expect_fully_used_expand(filename, ':r:e', 'c')
    end)

    itp(':r:r', function()
      expect_fully_used_expand(filename, ':r:r', 'src/version')
    end)

    itp(':r:r:r', function()
      expect_fully_used_expand(filename, ':r:r:r', 'src/version')
    end)
  end)

  describe('combining :e and :r', function()
    describe('single-extension filename', function()
      itp('handling a.c :e',                 function() expect_fully_used_expand('a.c',         ':e',         'c') end)
      itp('handling a.c :e:e',               function() expect_fully_used_expand('a.c',         ':e:e',       'c') end)
      itp('handling a.c :e:e:r',             function() expect_fully_used_expand('a.c',         ':e:e:r',     'c') end)
      itp('handling a.c :e:e:r:r',           function() expect_fully_used_expand('a.c',         ':e:e:r:r',   'c') end)
    end)

    describe('multiple-extension filename', function()
      itp('handling a.spec.rb :e',           function() expect_fully_used_expand('a.spec.rb',   ':e:r',       'rb') end)
      itp('handling a.spec.rb :e:r',         function() expect_fully_used_expand('a.spec.rb',   ':e:r',       'rb') end)
      itp('handling a.spec.rb :e:e:r',       function() expect_fully_used_expand('a.spec.rb',   ':e:e:r',     'spec') end)
      itp('handling a.spec.rb :e:e:r:r',     function() expect_fully_used_expand('a.spec.rb',   ':e:e:r:r',   'spec') end)
      itp('handling a.b.spec.rb :e:e:r',     function() expect_fully_used_expand('a.b.spec.rb', ':e:e:r',     'spec') end)
      itp('handling a.b.spec.rb :e:e:e:r',   function() expect_fully_used_expand('a.b.spec.rb', ':e:e:e:r',   'b.spec') end)
      itp('handling a.b.spec.rb :e:e:e:r:r', function() expect_fully_used_expand('a.b.spec.rb', ':e:e:e:r:r', 'b') end)

      itp('handling a.b.spec.rb :r:e',   function() expect_fully_used_expand('a.b.spec.rb', ':r:e',   'spec') end)
      itp('handling a.b.spec.rb :r:r:e', function() expect_fully_used_expand('a.b.spec.rb', ':r:r:e', 'b') end)
    end)
  end)
end)
