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
    assert.is_nil(resp)
    assert.is_nil(body)
  end)
end)
