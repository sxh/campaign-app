-module(campaigner_app_ffi).
-export([coerce/1, silence_stdout/1]).

coerce(X) -> X.

silence_stdout(F) ->
    GL = erlang:group_leader(),
    {ok, DevNull} = file:open("/dev/null", [write]),
    erlang:group_leader(DevNull, self()),
    try
        F()
    after
        erlang:group_leader(GL, self()),
        file:close(DevNull)
    end.
