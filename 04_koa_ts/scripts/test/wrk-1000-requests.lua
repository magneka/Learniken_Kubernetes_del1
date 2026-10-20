-- Lua script for wrk to send exactly 1000 requests.
--
-- wrk has no built-in request-count flag (-n is not a valid option), so the
-- limit is enforced here: the thread stops issuing requests once it has
-- received 1000 responses.
--
-- wrk itself still runs until the -d duration expires, so keep -d short and
-- read the "requests in" total rather than the Requests/sec average, which
-- is diluted by the idle remainder of the run.
local counter = 0
local max_requests = 1000

response = function(status, headers, body)
    counter = counter + 1
    if counter >= max_requests then
        wrk.thread:stop()
    end
end
