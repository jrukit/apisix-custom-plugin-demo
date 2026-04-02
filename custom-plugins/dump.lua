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
local encode = ngx.encode_base64
local jwt = require 'resty.jwt'
local openssl_pkey = require 'resty.openssl.pkey'
local json = require 'cjson'
local http = require 'resty.http'

function _M.check_schema(conf)
  return core.schema.check(schema, conf)
end

function _M.access(conf, ctx)
  core.log.warn("--- Hello from Custom Plugin: dump ---")
  return 200, encode("hello")
end

function _M.load_public_key(pem_string)
    if not pem_string then
        return nil, "PEM string is empty"
    end

    local pub, err = openssl_pkey.new(pem_string)
    if not pub then
        return nil, "failed to load public key: " .. (err or "unknown error")
    end

    return pub
end

return _M