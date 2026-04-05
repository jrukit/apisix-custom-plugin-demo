local plugin_name = "custom-signature-authorizer"

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

    local pub_key = {
        admin = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5CMNefT88zJlnaHmHJMtEXY58E1PvX8+9mzJ8PpuG55U2K1sPyRX/mKplwaGBsSF0kKowXyXsrqzGEXlbsNYQjTd2oUGv6I54UE6p8xbIEB90jCwyKkej91Phy7DjReEQWAOgV5WYCommDCkER7HPRVpF2aMR2rb+hcS7YWProwbnqfEJIh5A9oml4iyud/YCkHWFuPyTzBAhOUsiIotaJL89tta0Y5x42mSJaFLcypzyPo+CcpEJNFq5VE+C6vda++vJmklK29Za/b4AX8v1WzDsFHDVk+JFc8D4r1pyzVTyKbODni9M/BWzgoM37PMePg9bNMa0XmlrVTaFKIEkwIDAQAB\n-----END PUBLIC KEY-----",
        mocked_username = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5CMNefT88zJlnaHmHJMtEXY58E1PvX8+9mzJ8PpuG55U2K1sPyRX/mKplwaGBsSF0kKowXyXsrqzGEXlbsNYQjTd2oUGv6I54UE6p8xbIEB90jCwyKkej91Phy7DjReEQWAOgV5WYCommDCkER7HPRVpF2aMR2rb+hcS7YWProwbnqfEJIh5A9oml4iyud/YCkHWFuPyTzBAhOUsiIotaJL89tta0Y5x42mSJaFLcypzyPo+CcpEJNFq5VE+C6vda++vJmklK29Za/b4AX8v1WzDsFHDVk+JFc8D4r1pyzVTyKbODni9M/BWzgoM37PMePg9bNMa0XmlrVTaFKIEkwIDAQAB\n-----END PUBLIC KEY-----",
        mocked_unknown_username = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmZdgx9gIsImmNll7HkfWvCsPXwdzZVauOCdMHia7wAstBbUYUn5sBNbsgtJI1MeSKcdgQa9KCMe6AzyRr+AyI3yFWkXTqNPZ2EV4E3sc5xWVI5iFBCK1r3E86H/vth0GjPw+2th0ACJxPe3Bkl98K0jhY5Qinbi47KIOxQ1alDrfVzEAIj5Aba7wbZXuZ0BjPQd78lqPNKQAvziyjn9bglCnNDv/H+AW1VHTctmIa1qnprJMiImzGZi/egwG4GatrmdPjp+n9JAqXyID1Zd5aZZpV0TsdgMVYieRjtOCS+uWaYraDIciq7fG1pAW9nA6Eiy7MPyIYOs6mXOjMvnMxwIDAQAB\n-----END PUBLIC KEY-----",
    }
    return pub_key[username]
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

local function verify_sig(signature)
    local username = core.request.header(ctx, "username")
    local timestamp = core.request.header(ctx, "Timestamp")
    if not username or not timestamp then
        return false
    end

    local pub, err = openssl_pkey.new(fetch_pub_key(username))
    local data = timestamp .. username
    return pub and pub:verify(decode_base64(signature), data) or false
end

function _M.access(conf, ctx)
    local token_header = core.request.header(ctx, "Token")
    local sig_header = core.request.header(ctx, "X-Signature")

    if (not token_header or not verify_jwt(token_header)) and 
       (not sig_header or not verify_sig(sig_header)) then
        return 401, cjson.encode({
        status = "error",
        message = "Unauthorized",
        code = 40101
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