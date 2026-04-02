local mocked_core = {
    log = { warn = function() end },
}

package.loaded["apisix.core"]  = mocked_core

local actual = require("dump")

describe("test access", function()
  it("success", function()
    local conf = { body = "Test Success!" }
    local ctx = {}

    spy.on(mocked_core.log, "warn")

    local resp, body = actual.access(conf, ctx)

    assert.spy(mocked_core.log.warn).was.called()
    assert.equal(resp, 200)
    assert.equal(body, "aGVsbG8=")
  end)
end)

describe("load_public_key", function()
  it("success", function()
    local public_key_without_header = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmZdgx9gIsImmNll7HkfWvCsPXwdzZVauOCdMHia7wAstBbUYUn5sBNbsgtJI1MeSKcdgQa9KCMe6AzyRr+AyI3yFWkXTqNPZ2EV4E3sc5xWVI5iFBCK1r3E86H/vth0GjPw+2th0ACJxPe3Bkl98K0jhY5Qinbi47KIOxQ1alDrfVzEAIj5Aba7wbZXuZ0BjPQd78lqPNKQAvziyjn9bglCnNDv/H+AW1VHTctmIa1qnprJMiImzGZi/egwG4GatrmdPjp+n9JAqXyID1Zd5aZZpV0TsdgMVYieRjtOCS+uWaYraDIciq7fG1pAW9nA6Eiy7MPyIYOs6mXOjMvnMxwIDAQAB'
    local public_key = '-----BEGIN PUBLIC KEY-----\n' .. public_key_without_header .. '\n-----END PUBLIC KEY-----'
    local pub, err = actual.load_public_key(public_key)
        
    assert.is_nil(err)
    assert.is_equal(2048, pub:get_size() * 8)
  end)
end)