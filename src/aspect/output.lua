local concat = table.concat
local remove = table.remove
local setmetatable = setmetatable
local getmetatable = getmetatable
local print = print
local type = type
local ipairs = ipairs
local next = next
local tostring = tostring
local gsub = string.gsub
local ngx = ngx or {}
local err = require("aspect.err")
local e_pattern = require("aspect.config").escape.pattern
local e_replaces = require("aspect.config").escape.replaces
local runtime_error = err.runtime_error
local is_false = require("aspect.config").is_false
local is_empty_string = require("aspect.config").is_empty_string

--- Output handler
--- @class aspect.output
--- @field data table output fragments
--- @field line number
--- @field name string
--- @field name string
local output = {
    ipairs = ipairs,
    pairs = pairs,
    concat = table.concat,
    insert = table.insert,
    setmetatable = setmetatable
}

local function __call_collect(self, arg)
    self.data[#self.data + 1] = arg
end

local function __call_chunked(self, arg)

end

local function __tostring(self)
    return concat(self.data)
end

local mt_collect = {
    __call = __call_collect,
    __tostring = __tostring,
    __index = output,
}

local mt_print  = {
    __call = ngx.print or print,
    __tostring = __tostring,
    __index = output
}


function output.new(name, p, size, opts)
    return setmetatable({
        name = name,
        line = 0,
        data = {},
        p = p,
        size = size,
        stack = {},
        opts = opts,
    }, mt_collect)
end

function output:push_state(name)
    if #self.stack > self.opts.stack_size then
        runtime_error(self, "Call stack overflow (maximum " .. self.opts.stack_size .. ")")
    end
    self.stack[#self.stack + 1] = {self.name, self.line}
    self.name = name
    self.line = 0
    return self
end

function output:pop_state()
    if #self.stack > 0 then
        local stack = remove(self.stack)
        self.name = stack[1]
        self.line = stack[2]
    else
        runtime_error(self, "Internal error: call stack is empty. Broken template?")
    end
    return self
end

function output:get_callstack()
    local callstack = {"begin"}
    for _, c in ipairs(self.stack) do
        callstack[#callstack + 1 ]= c[1] .. ":" .. c[2]
    end
    callstack[#callstack + 1 ]= self.name .. ":" .. self.line
    return "\t" .. concat(callstack, "\n\t")
end

--- Cast value to boolean
--- @param v any
--- @return boolean
function output.b(v)
    if not v or is_false[v] or is_false[getmetatable(v)] then
        return false
    elseif type(v) == "table" then
        if v.__toboolean and getmetatable(v).__toboolean then
            v:__toboolean()
        elseif next(v) == nil then
            return false
        end
    end
    return true
end

--- Cast value to string
--- @param v any
--- @return string
function output.s(v)
    if not v or is_empty_string[v] or is_empty_string[getmetatable(v)] then
        return ""
    else
        return tostring(v)
    end
end

--- @param v any
--- @param ... string
function output.v(v, ...)
    for _, k in ipairs({...}) do
        if type(v) ~= "table" then
            return nil
        end
        if v[k] ~= nil then
            v = v[k]
        end
    end
    return v
end

function output:e(v)
    if self.escape then
        return self(gsub(v, e_pattern, e_replaces))
    else
        return self(v)
    end
end

local function join(t, delim)
    if type(t) == "table" then
        return concat(t, delim)
    else
        return tostring(t)
    end
end

function output:include(names, ignore, context)
    local view, error = self.opts.get(names)
    if error then
        runtime_error(self, error)
    elseif not view then
        if not ignore then
            runtime_error(self, "Template(s) not found. Trying " .. join(names, ", "))
        else
            return
        end
    end
    print("view", view)
    view.body(self:push_state(view.name), context)
    self:pop_state()
end


function output:fetch(names, ignore, context)
    local view, error = self.opts.get(names)
    if error then
        runtime_error(self, error)
    elseif not view and not ignore then
        runtime_error(self, "No one view (" .. join(names, ",") .. ") found")
    end
    view.body(self:push_state(view.name), context)
    self:pop_state()
end



return output