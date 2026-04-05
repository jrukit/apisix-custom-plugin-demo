local mocked_core = {
    log = { warn = function() end },
}

package.loaded["apisix.core"]  = mocked_core

local mocked_instance = {
    set_timeout = function(self, _) end,
    close = function(self) end,
    request_uri = function(self, _) return { status = 200 } end
}

local mocked_http = {
    new = function()
        return mocked_instance
    end
}

package.loaded["resty.http"]  = mocked_http

local actual = require("custom-signature-authorizer")
local cjson = require "cjson"

describe("fetch_pub_key", function()
  it("should be publick key.", function()
    local expected = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA5CMNefT88zJlnaHmHJMtEXY58E1PvX8+9mzJ8PpuG55U2K1sPyRX/mKplwaGBsSF0kKowXyXsrqzGEXlbsNYQjTd2oUGv6I54UE6p8xbIEB90jCwyKkej91Phy7DjReEQWAOgV5WYCommDCkER7HPRVpF2aMR2rb+hcS7YWProwbnqfEJIh5A9oml4iyud/YCkHWFuPyTzBAhOUsiIotaJL89tta0Y5x42mSJaFLcypzyPo+CcpEJNFq5VE+C6vda++vJmklK29Za/b4AX8v1WzDsFHDVk+JFc8D4r1pyzVTyKbODni9M/BWzgoM37PMePg9bNMa0XmlrVTaFKIEkwIDAQAB\n-----END PUBLIC KEY-----"

    spy.on(mocked_instance, "request_uri")

    assert.equal(expected, actual.fetch_pub_key("mocked_username"))
    assert.spy(mocked_instance.request_uri).was_called_with(
      match._,
      "https://httpbun.com", 
      match.is_table({ method = "GET", ssl_verify = false })
    )
  end)

  it("should be nil with username does not match.", function()
    spy.on(mocked_instance, "request_uri")

    assert.is_nil(actual.fetch_pub_key("mocked_username_0007"))
    assert.spy(mocked_instance.request_uri).was_called_with(
      match._,
      "https://httpbun.com", 
      match.is_table({ method = "GET", ssl_verify = false })
    )
  end)

  it("should be nil with http status is 500.", function()
    mocked_instance.request_uri = function(_, _)
      return { status = 500 }
    end

    spy.on(mocked_instance, "request_uri")

    assert.is_nil(actual.fetch_pub_key("mocked_username_0007"))
    assert.spy(mocked_instance.request_uri).was_called_with(
      match._,
      "https://httpbun.com", 
      match.is_table({ method = "GET", ssl_verify = false })
    )

    mocked_instance.request_uri = function(_, _)
      return { status = 200 }
    end
  end)

  it("should be nil with http status is 400.", function()
    mocked_instance.request_uri = function(_, _)
      return { status = 400 }
    end

    spy.on(mocked_instance, "request_uri")

    assert.is_nil(actual.fetch_pub_key("mocked_username_0007"))
    assert.spy(mocked_instance.request_uri).was_called_with(
      match._,
      "https://httpbun.com", 
      match.is_table({ method = "GET", ssl_verify = false })
    )

    mocked_instance.request_uri = function(_, _)
      return { status = 200 }
    end
  end)
end)

describe("extract_username", function()
  it("should be username.", function()
    local token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1vY2tlZF91c2VybmFtZSJ9.EajRp033Z3fSJMWcshy9nm9dgiGT0gLU3bR6kDRwlSPKXXATzhluuYQu3OJZS4aoKgtcYQuT7LKVbBDnohtpYxIjeNPycrwxJKwGMLZjVzK_afsKKqlGk0cGtnmP7B2tc2wLQLBaheHHXZO684PNBN3L-8rXiNjZ8psGY3YNpY29BlDCt5P4-G1fBm6DKClOWAB_P_aslarB_M0MqjiB1RiXUhEOiqA0F4QxY8E03cZdWoJbCLiUOlR2hTAzBV_A6qGb3zeH2cMoNMRw56Ci0oygvuPj0hSPjSZ8XYt6FvcTvWXgyX9DgLdLZOImH5VqzdVXYaxCaJosMi3gk_8d1Q"

    assert.equal("mocked_username", actual.extract_username(token))
  end)

  it("should be nil with token no has username.", function()
    local token_no_has_username = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.JfMf4R5aalmF7D1hKxD8Ecf2oLSQNh4kL0u-d5zf9TFY-sin1Dw5ACzhxY8s2tU7s0WmehqFLr4JlImxUTIJyoXz1ty1CXSXuQ5s_01sbrCWJJU8FH19I6XONfxv4dzg2LPyOBEOjGZGIy12n2TROdXsVe9Gwfz-qnChXjlLe-3MkWyvKOMgfeouBM2VIXPcAdplEt1CFY5LkpN_iWPV-yaAYLVpiJnAyoaTjQfQ1SLCERxcUnFKMtvj3fkqBfgkegkBKeeQf_lTfnTiUO2wjzJE2VEkh7fpKBTkMQjQWgwTWYqSR9BcJnezXNAscZkADPRW160BoXDW_PaepX_XpQ"

    assert.is_nil(actual.extract_username(token))
  end)

  it("should be nil with token is expired.", function()
    local token_no_has_username = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1vY2tlZC11c2VybmFtZSIsImV4cCI6MTUwNjIzOTAyMn0.P4TnpxPnMMhFB9ReXguAW0synfuguFvChRATKiMgvi0WTwMc8o7SfmxBJsXGzuZFaDbuKwLFT4VkBi_55u9jFdd42BSwPrLdYC6Kzddj4Ah5IvBj3_3RLQCDoOobwxb9afS4jfMVcCZKiJDBaWdAe6YpMKOtxiaIWHHU4w_E-e-2rZDpkB4tA9wWO1zzMjtY8bqyHfH2O2VR8D8gXgFQEscU6TkWSK4sD2bLn8kxvePA9u_OR8oWWnYS-T_EiTDliy4EhH4S-JRAz_q8suNm7T4k4sH28k5UD4a5jYoGL0eltjAiwW9HghtcWmVaHZTRegx6ZgqqTACVmgbn5iln3Q"

    assert.is_nil(actual.extract_username(token))
  end)

  it("should be nil with token is malformed.", function()
    assert.is_nil(actual.extract_username("malformed"))
  end)
end)

describe("verify_jwt", function()
  it("should be true.", function()
    local token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1vY2tlZF91c2VybmFtZSJ9.EajRp033Z3fSJMWcshy9nm9dgiGT0gLU3bR6kDRwlSPKXXATzhluuYQu3OJZS4aoKgtcYQuT7LKVbBDnohtpYxIjeNPycrwxJKwGMLZjVzK_afsKKqlGk0cGtnmP7B2tc2wLQLBaheHHXZO684PNBN3L-8rXiNjZ8psGY3YNpY29BlDCt5P4-G1fBm6DKClOWAB_P_aslarB_M0MqjiB1RiXUhEOiqA0F4QxY8E03cZdWoJbCLiUOlR2hTAzBV_A6qGb3zeH2cMoNMRw56Ci0oygvuPj0hSPjSZ8XYt6FvcTvWXgyX9DgLdLZOImH5VqzdVXYaxCaJosMi3gk_8d1Q"

    assert.is_true(actual.verify_jwt(token))
  end)

  it("should be false with not found username in token.", function()
    local token_no_has_username = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1vY2tlZC11c2VybmFtZSIsImV4cCI6MTUwNjIzOTAyMn0.P4TnpxPnMMhFB9ReXguAW0synfuguFvChRATKiMgvi0WTwMc8o7SfmxBJsXGzuZFaDbuKwLFT4VkBi_55u9jFdd42BSwPrLdYC6Kzddj4Ah5IvBj3_3RLQCDoOobwxb9afS4jfMVcCZKiJDBaWdAe6YpMKOtxiaIWHHU4w_E-e-2rZDpkB4tA9wWO1zzMjtY8bqyHfH2O2VR8D8gXgFQEscU6TkWSK4sD2bLn8kxvePA9u_OR8oWWnYS-T_EiTDliy4EhH4S-JRAz_q8suNm7T4k4sH28k5UD4a5jYoGL0eltjAiwW9HghtcWmVaHZTRegx6ZgqqTACVmgbn5iln3Q"

    assert.is_false(actual.verify_jwt(token_no_has_username))
  end)
end)

describe("verify_sig", function()
  it("should be true.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "username" then
          return "mocked_username"
        else
            return "1516239022"
        end
      end
    }
    local signature = "H97SMgCZOxDNMBvJ+CxOtJjC0AXGop0sAMSxh/J+fVn6SdAooILe1APPG2GjeDmsPy3fXh7gFucB0mhkwfCtNK1FrwHfU/gfpN8wplh9xDeTmpMeuUCEyHuNJVSRQSUj/mUeW3mWI7ufOg7i/B2yi8PmxPVWrs66l88TzOwit8iZN0P7AEJ9+BRaILKpOzY5VNqxjHnK9mTswyXgXRgG1Z6q15KgoOgUB5aXWigSb7snnA0G/HOTpHcoJTgGgF9kh1N59cZPUqm9M908vMj91RRhsmPtkUfVSva9r6Nz5bykW2uF0BB6mxe4p1Bt4OshufBL/lzshqarC0jA0BUJ3A=="
    
    assert.is_true(actual.verify_sig(signature))
  end)

  it("should be false with malformed signature.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "username" then
          return "mocked_username"
        else
            return "1516239022"
        end
      end
    }
    local signature = "malformed"

    assert.is_false(actual.verify_sig(signature))
  end)

  it("should be false with signature not matched.", function()
    mocked_core.request = {
      header = function(_)
        return "mocked_username"
      end
    }
    -- signature is "invalid:invalid"
    local signature = "bh3jHE9Z/G0Hy/cK/a+XSu0WMLhf0xliKTyBeblRL2bPJpAGuDYqzCu6NRbJbTbpIsKyClqg+yLMPhSXDd2Tm33uPaaZfO8CJZxdtsg3/2Un+YH5ueCUR0HvMaIiNbygr4oAOQHq1yNEw1usV5xFqQlHdPVWJf0HRiX25JqEvQ2ZFWu8w206bHRDSK6IHu6WfMoO4fYdGLYRfPmv1Hw5fxS7wlSc6teV7JwSrS+TbQdzgyn4aupKEZVVcjSCYyHg/7pSPTbKKQBT8k/YLICCB0iUHDJ39xDHrR6fC0a2PkBHIyZwOLB+nnQbUN2wtKLk1d8kDb+0UHbrot69Zcubrg=="

    assert.is_false(actual.verify_sig(signature))
  end)

  it("should be false with key pair not matched.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "username" then
          return "mocked_unknown_username"
        else
            return "1516239022"
        end
      end
    }
    local signature = "LlPjkJFoZZyBEjHAluqv28kNN2aS48yNfk7L1j9cFtn42V++G9lq9NKnS6wDa22lN+91aRBbMA/lv7pnOH8JdvxnbWuiRbhP1xfVp4jK7v2GkVMcM8Wwv4Bs+sNjlOTbgdqBnxyQUOTgZRnGk1TBGtZC2vOKw6AFWI3Us2huRONNKcy45/RDlgY+KGhIIrd46IQ+HByBGsVESjLlmePaegPA2DbB3twMvsRytYd7zNTQ0zOSyI4ppPMRdX9nzQ9dgTveHI2Vqem7qSTODR5DmZCXixK9P7uBguKN6EwpRknHtpsO/IjYMvpp3AOQwQ9ERlKEc5bvgJiYpmj/Ck3qSw=="
  
    assert.is_false(actual.verify_sig(signature))
  end)

  it("should be false with username headers is nil.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "username" then
          return nil
        else
            return "1516239022"
        end
      end
    }
    local signature = "H97SMgCZOxDNMBvJ+CxOtJjC0AXGop0sAMSxh/J+fVn6SdAooILe1APPG2GjeDmsPy3fXh7gFucB0mhkwfCtNK1FrwHfU/gfpN8wplh9xDeTmpMeuUCEyHuNJVSRQSUj/mUeW3mWI7ufOg7i/B2yi8PmxPVWrs66l88TzOwit8iZN0P7AEJ9+BRaILKpOzY5VNqxjHnK9mTswyXgXRgG1Z6q15KgoOgUB5aXWigSb7snnA0G/HOTpHcoJTgGgF9kh1N59cZPUqm9M908vMj91RRhsmPtkUfVSva9r6Nz5bykW2uF0BB6mxe4p1Bt4OshufBL/lzshqarC0jA0BUJ3A=="
    
    assert.is_false(actual.verify_sig(signature))
  end)

  it("should be false with timestamp headers is nil.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "username" then
          return "mocked_username"
        else
            return nil
        end
      end
    }
    local signature = "H97SMgCZOxDNMBvJ+CxOtJjC0AXGop0sAMSxh/J+fVn6SdAooILe1APPG2GjeDmsPy3fXh7gFucB0mhkwfCtNK1FrwHfU/gfpN8wplh9xDeTmpMeuUCEyHuNJVSRQSUj/mUeW3mWI7ufOg7i/B2yi8PmxPVWrs66l88TzOwit8iZN0P7AEJ9+BRaILKpOzY5VNqxjHnK9mTswyXgXRgG1Z6q15KgoOgUB5aXWigSb7snnA0G/HOTpHcoJTgGgF9kh1N59cZPUqm9M908vMj91RRhsmPtkUfVSva9r6Nz5bykW2uF0BB6mxe4p1Bt4OshufBL/lzshqarC0jA0BUJ3A=="
    
    assert.is_false(actual.verify_sig(signature))
  end)

  it("should be false with both usrname and timestamp headers are nil.", function()
    mocked_core.request = {
      header = function(_, x)
        return nil
      end
    }
    local signature = "H97SMgCZOxDNMBvJ+CxOtJjC0AXGop0sAMSxh/J+fVn6SdAooILe1APPG2GjeDmsPy3fXh7gFucB0mhkwfCtNK1FrwHfU/gfpN8wplh9xDeTmpMeuUCEyHuNJVSRQSUj/mUeW3mWI7ufOg7i/B2yi8PmxPVWrs66l88TzOwit8iZN0P7AEJ9+BRaILKpOzY5VNqxjHnK9mTswyXgXRgG1Z6q15KgoOgUB5aXWigSb7snnA0G/HOTpHcoJTgGgF9kh1N59cZPUqm9M908vMj91RRhsmPtkUfVSva9r6Nz5bykW2uF0BB6mxe4p1Bt4OshufBL/lzshqarC0jA0BUJ3A=="
    
    assert.is_false(actual.verify_sig(signature))
  end)
end)

describe("access", function()
  it("should be nil with token valid.", function()
    local mocked_token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6Im1vY2tlZF91c2VybmFtZSJ9.EajRp033Z3fSJMWcshy9nm9dgiGT0gLU3bR6kDRwlSPKXXATzhluuYQu3OJZS4aoKgtcYQuT7LKVbBDnohtpYxIjeNPycrwxJKwGMLZjVzK_afsKKqlGk0cGtnmP7B2tc2wLQLBaheHHXZO684PNBN3L-8rXiNjZ8psGY3YNpY29BlDCt5P4-G1fBm6DKClOWAB_P_aslarB_M0MqjiB1RiXUhEOiqA0F4QxY8E03cZdWoJbCLiUOlR2hTAzBV_A6qGb3zeH2cMoNMRw56Ci0oygvuPj0hSPjSZ8XYt6FvcTvWXgyX9DgLdLZOImH5VqzdVXYaxCaJosMi3gk_8d1Q"
    mocked_core.request = {
      header = function(_, x)
        if x == "Token" then
          return mocked_token
        end
      end
    }
        
    local status, body = actual.access({}, {})

    assert.is_nil(status)
    assert.is_nil(body)
  end)

  it("should be nil with signature valid.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "Token" then
          return nil
        elseif x == "X-Signature" then
          return "H97SMgCZOxDNMBvJ+CxOtJjC0AXGop0sAMSxh/J+fVn6SdAooILe1APPG2GjeDmsPy3fXh7gFucB0mhkwfCtNK1FrwHfU/gfpN8wplh9xDeTmpMeuUCEyHuNJVSRQSUj/mUeW3mWI7ufOg7i/B2yi8PmxPVWrs66l88TzOwit8iZN0P7AEJ9+BRaILKpOzY5VNqxjHnK9mTswyXgXRgG1Z6q15KgoOgUB5aXWigSb7snnA0G/HOTpHcoJTgGgF9kh1N59cZPUqm9M908vMj91RRhsmPtkUfVSva9r6Nz5bykW2uF0BB6mxe4p1Bt4OshufBL/lzshqarC0jA0BUJ3A=="
        elseif x == "username" then
          return "mocked_username"
        else
            return "1516239022"
        end
      end
    }

    local status, body = actual.access({}, {})

    assert.is_nil(status)
    assert.is_nil(body)
  end)

  it("should be 401 with token invalid.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "Token" then
          return "malformed"
        elseif x == "X-Signature" then
          return nil
        end
      end
    }

    local status, body = actual.access({}, {})

    assert.equal(401, status)
    assert.equal(cjson.encode({
        status = "error",
        message = "Unauthorized",
        code = 40101
    }), body, body)
  end)

    it("should be 401 with signature invalid.", function()
    mocked_core.request = {
      header = function(_, x)
        if x == "Token" then
          return nil
        elseif x == "X-Signature" then
          return "malformed"
        elseif x == "username" then
          return "mocked_username"
        else
            return "1516239022"
        end
      end
    }

    local status, body = actual.access({}, {})

    assert.equal(401, status)
    assert.equal(cjson.encode({
        status = "error",
        message = "Unauthorized",
        code = 40101
    }), body)
  end)

  it("should be 401 with token and signature do not exist.", function()
    mocked_core.request = {
      header = function(_)
        return nil
      end
    }

    local status, body = actual.access({}, {})

    assert.equal(401, status)
    assert.equal(cjson.encode({
        status = "error",
        message = "Unauthorized",
        code = 40101
    }), body)
  end)
end)