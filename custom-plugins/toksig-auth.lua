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

local function verify_sig(sig, username, ts)
    local pub, err = openssl_pkey.new(fetch_pub_key(username))
    local data = ts .. username
    local alg = "sha256"

    return pub and pub:verify(decode_base64(sig), data, alg) or false
end

local function print_jwt_info(jwt_obj)
    local info_string = "{\"plugin_name\":\"toksig-auth\"}"
    local info_json = cjson.decode(info_string)
    info_json.header = jwt_obj.header or nil
    info_json.payload = jwt_obj.payload or nil
    info_json.status = jwt_obj.valid and "success" or "failed"
    core.log.info(string.format("Load JWT %s [Plugin: %s]", info_json.status, info_json.plugin_name))
    core.log.info(string.format("This is information: %s", cjson.encode(info_json)))
end

local function extract_username(token)
    local jwt_obj = jwt:load_jwt(token)
    if not jwt_obj.valid or not jwt_obj.payload.username then
        print_jwt_info(jwt_obj)
        return nil
    end

    print_jwt_info(jwt_obj)

    return jwt_obj.payload.username
end

local function verify_jwt(token)
    local username = extract_username(token)

    return username ~= nil and jwt:verify(fetch_pub_key(username), token).verified
end

local function is_present(s)
    return s ~= nil and s ~= ""
end

local function is_jwt_valid(token)
    return is_present(token) and verify_jwt(token)
end

local function is_sig_valid(token, sig, username, ts)
    return not is_present(token) and verify_sig(sig, username, ts)
end

local function has_sig_bundle(sig, username, ts)
    return is_present(sig) and is_present(username) and is_present(ts)
end

function _M.access(conf, ctx)
    local token = core.request.header(ctx, "Token")
    local sig = core.request.header(ctx, "X-Signature")
    local username = core.request.header(ctx, "username")
    local ts = core.request.header(ctx, "Timestamp")

    if not is_present(token) and not has_sig_bundle(sig, username, ts) then
        return 403, "Forbidden"
    end

    if not is_jwt_valid(token) and not is_sig_valid(token, sig, username, ts) then
        return 401, "Unauthorized"
    end
end

if _G._TEST then
    _M.fetch_pub_key = fetch_pub_key
    _M.verify_sig = verify_sig
    _M.extract_username = extract_username
    _M.verify_jwt = verify_jwt
    _M.is_present = is_present
    _M.is_jwt_valid = is_jwt_valid
    _M.is_sig_valid = is_sig_valid
    _M.has_sig_bundle = has_sig_bundle
end

return _M