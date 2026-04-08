local plugin_name = "dump"

local schema = {
    type = "object",
    properties = {
        body = {
            description = "custom response to replace the Upstream response with.",
            type = "string"
        },
    },
    required = {"body"},
}

local _M = {
    version = 0.1,
    priority = 23,
    name = plugin_name,
    schema = schema,
}

local core = require 'apisix.core'

function _M.check_schema(conf)
  return core.schema.check(schema, conf)
end

function _M.access(conf, ctx)
  core.log.warn("--- Hello from Custom Plugin: dump ---")
end

return _M