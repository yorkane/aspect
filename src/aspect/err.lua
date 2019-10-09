local setmetatable = setmetatable
local error = error
local type = type
local traceback = debug.traceback

--- @class aspect.error
--- @field code string
--- @field line number
--- @field name string
--- @field message string
--- @field callstack string
--- @field traceback string
--- @field context string
local err = {
    _NAME = "error"
}

--- @param e aspect.error
local function to_string(e)
    local msg
    if e.name then
        msg = e.code .. " error: " .. e.message .. " in " .. e.name .. ":" .. e.line
    else
        msg = e.code .. " error: " .. e.message
    end
    if e.context then
        msg = msg .. "\nContext: " .. e.context .. " <-- there"
    end
    if e.callstack then
        msg = msg .. "\nCallstack:\n" .. e.callstack
    end
    if e.traceback then
        msg = msg .. "\nLua " .. e.traceback
    end
    return msg
end

local mt = {
    __index = err,
    __tostring = to_string
}

--- @param tok aspect.tokenizer
--- @param code string
--- @param message string
function err.compiler_error(tok, code, message)
    local fields = {
        code = code,
        traceback = traceback(),
    }
    if tok then
        if tok:is_valid() then
            fields.message = "unexpected token '" .. tok:get_token() .. "', " .. message
        else
            fields.message = "unexpected end of tag, " .. message
        end
        fields.context = tok:get_path_as_string()
    else
        fields.message = message
    end
    error(fields)
end

--- @param __ aspect.output
--- @param message string|aspect.error
function err.runtime_error(__, message)
    local e = err.new(message)
        :set_code("runtime")
        :set_name(__.name, __.line, __:get_callstack())
    error(e)
end

function err.is(wtf)
    return type(wtf) == "table" and wtf._NAME == "error"
end

function err.new(e)
    if type(e) ~= 'table' then
        e = {
            message = tostring(e),
        }
    elseif e._NAME == "error" then
        return e
    end


    return setmetatable({
        code = e.code or "internal",
        line = e.line or 0,
        name = e.name or "runtime",
        message = e.message,
        callstack = nil,
        traceback = e.traceback or traceback(),
        context = e.context,
    }, mt)
end

function err:set_code(code)
    self.code = code
    return self
end

function err:set_name(name, line, callstack)
    self.name = name
    self.line = line
    self.callstack = callstack
    return self
end




return err