local plugin_name = "toksig-auth"

local schema = {
    type = "object",
    properties = {
        body = {
            description = "custom response to replace the Upstream response with.",
            type = "string",
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

local core = require "apisix.core"
local decode_base64 = ngx.decode_base64
local jwt = require "resty.jwt"
local openssl_pkey = require "resty.openssl.pkey"
local cjson = require "cjson"
local http = require "resty.http"

function _M.check_schema(conf)
  return core.schema.check(schema, conf)
end

local function fetch_pub_key(username)
    local httpc = http.new()
    httpc:set_timeout((timeout or 10000))
    local res, err = httpc:request_uri("https://httpbun.com", { method = "GET", ssl_verify = false })
    httpc:close()

    if not res or res.status ~= 200 then
        return nil
    end

    local local_conf = core.config.local_conf()
    local attr = local_conf.plugin_attr and local_conf.plugin_attr["toksig-auth"]

    local pub_keys = attr and attr.pub_keys or {}
    return pub_keys[username]
end

local function extract_username(token)
    local jwt_obj = jwt:load_jwt(token)
    if not jwt_obj.valid or not jwt_obj.payload.username then
        return nil
    end

    return jwt_obj.payload.username
end

local function verify_jwt(token)
    local username = extract_username(token)

    return username and
           jwt:verify(fetch_pub_key(username), token).verified
end

local function verify_sig(signature, username, timestamp)
    local pub, err = openssl_pkey.new(fetch_pub_key(username))
    local data = timestamp .. username
    return pub and pub:verify(decode_base64(signature), data) or false
end

function _M.access(conf, ctx)
    local token_header = core.request.header(ctx, "Token")
    local sig_header = core.request.header(ctx, "X-Signature")
    local username = core.request.header(ctx, "username")
    local timestamp = core.request.header(ctx, "Timestamp")

    if not token_header and 
       not (sig_header and username and timestamp) then
        return 403, cjson.encode({
        status = "error",
        message = "Forbidden",
        code = 40301,
        })
    end

    if not (token_header and verify_jwt(token_header)) and 
       not (sig_header and verify_sig(sig_header, username, timestamp)) then
        return 401, cjson.encode({
        status = "error",
        message = "Unauthorized",
        code = 40101,
        })
    end
end

if _G._TEST then
    _M.fetch_pub_key = fetch_pub_key
    _M.extract_username = extract_username
    _M.verify_jwt = verify_jwt
    _M.verify_sig = verify_sig
end
return _M