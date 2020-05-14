local setmetatable = setmetatable
local compiler = require("aspect.compiler")
local output = require("aspect.output")
local funcs = require("aspect.funcs")
local filters = require("aspect.filters")
local tests = require("aspect.tests")
local err = require("aspect.error")
local utils = require("aspect.utils")
local tag_type = require("aspect.config").compiler.tag_type
local var_dump = utils.var_dump
local loadcode
local loadchunk
local _VERSION = _VERSION
local loadstring = loadstring
local load = load
local setfenv = setfenv
local function_dump = string.dump
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local type = type
local pcall = pcall
local jit = jit


--- View
--- @class aspect.view
--- @field name string
--- @field body function
--- @field macros table<fun(__:aspect.output, context:table)>
--- @field blocks table<aspect.template.block>
--- @field vars table<string>
--- @field uses table<string>
--- @field extends string|boolean
--- @field cached string
--- @field has_blocks boolean
--- @field has_macros boolean
local _ = {}

--- @class aspect.template.block
--- @field desc string block description
--- @field body fun(__: aspect.output, context: table) block's code
--- @field vars table used context variables
--- @field parent boolean use parent() function inside
local _ = {}


--- @class aspect.template
--- @field compiler aspect.compiler
--- @field stats boolean
--- @field cache boolean|table enable or disable in-memory cache. by default: false. set table (as container) for enable cache.
--- @field loader fun(name: string):string,string template source code loader with etag (optionally)
--- @field luacode_load fun(name: string, tpl: aspect.template):string
--- @field luacode_save fun(name: string, luacode: string, tpl: aspect.template)
--- @field bytecode_load fun(name: string, tpl: aspect.template):string
--- @field bytecode_save fun(name: string, bytecode: string, tpl: aspect.template)
local template = {
    _VERSION = "1.12",
    _NAME = "aspect",
}
local mt = { __index = template }

do
    if _VERSION == "Lua 5.1" then
        if jit then
            loadchunk = function(tpl, code, name)
                return load(code, name, nil, tpl.env)
            end
        else
            loadchunk = function(tpl, code, name)
                local func, error = loadstring(code, name)
                if func then
                    setfenv(func, tpl.env)
                end
                return func, error
            end
        end
    else
        loadchunk = function(tpl, code, name)
            return load(code, name, nil, tpl.env)
        end
    end
    --- @param tpl aspect.template
    --- @param code string
    --- @param name string the template name
    loadcode = function (tpl, code, name)
        local error
        if type(code) == 'string' then
            code, error = loadchunk(tpl, code, name .. ".lua")
            if error then
                return nil, err.new("Error loading '" .. name .. "' code: " .. tostring(error))
            end
        end
        if type(code) ~= 'function' then
            return nil, err.new("loaded view '" .. name .. "' is not valid a function or bytecode")
        end
        local view = code()
        view.has_blocks = (utils.nkeys(view.blocks) > 0)
        view.has_macros = (utils.nkeys(view.macros) > 0)
        return view
    end
end

--- @param options table
function template.new(options)
    options = options or {}
    local tpl = setmetatable({
        cache = false,
        compiler = compiler,
        loader = options.loader,
        env = options.env or {},
        luacode_load = options.luacode_load,
        luacode_save = options.luacode_save,
        bytecode_load = options.bytecode_load,
        bytecode_save = options.bytecode_save,
    }, mt)
    if options.cache then
        if options.cache == true then
            tpl.cache = {}
        else
            tpl.cache = options.cache
        end
    end
    tpl.opts = {
        escape = options.autoescape or false,
        strip = options.autostrip or false,
        stack_size = 20,
        f = filters.fn,
        fn = funcs.fn,
        t = tests.fn
    }
    tpl.stats = options.stats or true
    --- @param names table|string
    tpl.opts.get = function(names)
        local view, error
        if type(names) == "table" then
            for _, n in ipairs(names) do
                view, error = tpl:get_view(n)
                if error then
                    return nil, error
                elseif view then
                    return view
                end
            end
        else
            view, error = tpl:get_view(names)
            if error then
                return nil, error
            elseif view then
                return view
            end
        end
    end
    return tpl
end

--- Compile the template
--- @return aspect.compiler
--- @return aspect.error
function template:compile(name)
    local source, error, ok, cmp
    source, error = self.loader(name, self)
    if not source then
        return nil, nil, err.new(error)
    end
    cmp = self.compiler.new(self, name)
    ok, error = cmp:run(source)
    if not ok then
        return nil, error
    else
        return cmp
    end
end

--- @param name string
--- @param source string
--- @return aspect.compiler
--- @return aspect.error
function template:compile_code(name, source)
    local cmp = self.compiler.new(self, name)
    local ok, error = cmp:run(source)
    if not ok then
        return nil, error
    else
        return cmp
    end
end

--- Returns the view
--- @param name string the view name
--- @return aspect.view|nil
--- @return aspect.error|nil
--- @return aspect.compiler|nil
function template:get_view(name)
    if self.cache and self.cache[name] then
        return self.cache[name]
    end
    local view, error, build = self:load(name)
    if view then
        if view.uses then -- lazy load {% use %} tags
            for _, use in ipairs(view.uses) do
                local use_view, use_error = self:get_view(use.name)
                if use_view then -- use template loaded
                    if use_view.has_blocks then -- loaded template has blocks
                        if use.with then -- we use peace of blocks
                            for n, a in pairs(use.with) do
                                if not view.blocks[a] and use_view.blocks[n] then
                                    view.blocks[a] = use_view.blocks[n]
                                end
                            end
                        else
                            for n, b in pairs(use_view.blocks) do
                                if not view.blocks[n] then
                                    view.blocks[n] = b
                                end
                            end
                        end
                    end
                else
                    return nil, err.new("Failed to load block from template " .. name .. ": " .. err.new(use_error):get_message())
                        :set_name(self.name, use_view.line), build
                end
            end
        end
        if self.cache then -- if cache are enabled
            self.cache[name] = view
        end
        return view
    elseif error then
        return nil, err.new(error), build
    else
        return nil
    end
end

--- Load template and compile template if needed.
--- This method works without internal template cache.
--- @param name string the view name
--- @return aspect.view|nil
--- @return aspect.error or nil if OK
--- @return aspect.compiler or nil of the template from cache
function template:load(name)
    local bytecode, luacode, source, build, ok, error, f
    if self.bytecode_load then
        bytecode, error = self.bytecode_load(name, self)
        if bytecode then
            return loadcode(self, bytecode, name)
        elseif error then
            return nil, err.new(error)
        end
    end
    if self.luacode_load then
        luacode, error = self.luacode_load(name, self)
        if luacode then
            return loadcode(self, luacode, name)
        elseif error then
            return nil, err.new(error)
        end
    end
    source, error = self.loader(name, self)

    if source then
        build = self.compiler.new(self, name)
        ok, error = build:run(source)
        if ok then
            luacode = build:get_code()
            local view, load_error = loadcode(self, luacode, name)
            if not view then
                return nil, load_error
            end
            if self.luacode_save then
                self.luacode_save(name, luacode, self)
            end
            if self.bytecode_save then
                f, error = (loadstring or load)(luacode, name .. ".lua")
                if not f then
                    return nil, err.new(error or "Failed to dump a view " .. name), build
                end
                self.bytecode_save(name, function_dump(f), self)
            end
            return view, nil, build
        else
            return nil, error, build
        end
    elseif error then
        return nil, err.new(error, "compile")
    else
        return nil
    end
end

--- Returns template result as string
--- @param name string
--- @param vars table
--- @return aspect.output template result
--- @return aspect.error if error occur
function template:render(name, vars, options)
    local out, ok = output.new(self.opts, vars, options or {}), nil
    local view, error = self:get_view(name)
    if not view then
        return out, err.new(error or "Template '" .. tostring(name) .. "' not found")
    end
    out:add_blocks(view)
    while view.extends do
        local extends = view.extends
        if extends == true then -- dynamic extends
            ok, extends = pcall(view.body, out, vars)
            if not ok then
                if err.is(extends) then
                    return out, extends
                else
                    return out, err.new({
                        code = "runtime",
                        name = view.name,
                        line = out.line,
                        message = tostring(extends)
                    })
                end
            end
        end
        local v, e = self:get_view(extends)
        if not v then
            return nil, err.new(e or "Template '" .. tostring(view.extends) .. "' not found while extending " .. name)
        end
        view = v
        out:add_blocks(view)
    end
    ok, error = pcall(view.body, out, vars)
    if ok then
        return out:finish()
    elseif err.is(error) then
        return out:finish(), error
    else
        return out:finish(), err.new({
            code = "runtime",
            name = view.name,
            line = out.line,
            message = tostring(error)
        })
    end
end

--- Returns macro result as string
--- @param name string the template name
--- @param macro_name string the macro name
--- @param arguments table of arguments for macro
--- @return aspect.output macro result
--- @return aspect.error if error occur
function template:render_macro(name, macro_name, arguments)
    local out, ok = output.new(self.opts, arguments, {}), nil
    local view, error = self:get_view(name)
    if not view then
        return nil, err.new(error or "Template '" .. tostring(name) .. "' not found")
    end
    if view.macros[macro_name] then
        ok, error = pcall(view.macros[macro_name], out, arguments)
        if ok then
            return tostring(out)
        else
            return out:finish(), err.runtime_error(out, error)
        end
    else
        return out:finish(), err.new({
            name = view.name,
            message = "Macro '" .. macro_name .. "' not found"
        })
    end
end

--- Returns block result as string
--- @param name string the template name
--- @param block_name string the block name
--- @param vars table of arguments for block
--- @return aspect.output block result
--- @return aspect.error if error occur
function template:render_block(name, block_name, vars)
    local out, ok = output.new(self.opts, vars, {}), nil
    local view, error = self:get_view(name)
    if not view then
        return nil, err.new(error or "Template '" .. tostring(name) .. "' not found")
    end
    if view.blocks and view.blocks[block_name] then
        ok, error = pcall(view.blocks[block_name].body, out, vars)
        if ok then
            return tostring(out)
        else
            return out:finish(), err.runtime_error(out, error)
        end
    else
        return out:finish(), err.new{
            name = name,
            message = "Block '" .. block_name .. "' not found"
        }
    end
end

--- Print template result
--- @param name string|table
--- @param vars table
--- @param chunk_size number
--- @return aspect.output
function template:display(name, vars, chunk_size)
    return self:render(name, vars, {
        chunk_size = chunk_size,
        print = true
    })
end

--- Generate template result send into callback chunk by chunk
--- @param name string|table
--- @param vars table
--- @param callback fun(out:aspect.output, chunk:string)
--- @param chunk_size number
--- @return aspect.output
function template:generate(name, vars, callback, chunk_size)
    return self:render(name, vars, {
        chunk_size = chunk_size,
        print = callback
    })
end

return template