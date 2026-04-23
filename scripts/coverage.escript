#!/usr/bin/env escript
%%! -boot start_clean -pa build/dev/erlang/campaigner_app/ebin -pa build/dev/erlang/gleam_stdlib/ebin -pa build/dev/erlang/gleam_erlang/ebin -pa build/dev/erlang/lustre/ebin -pa build/dev/erlang/gleam_json/ebin -pa build/dev/erlang/gleam_otp/ebin -pa build/dev/erlang/houdini/ebin -pa build/dev/erlang/gleeunit/ebin -pa build/dev/erlang/gleam_javascript/ebin

main(_) ->
  cover:start(),

  {ok, _} = cover:compile_beam(campaigner_app),
  {ok, _} = cover:compile_beam(campaigner_app_test),

  TestModules = discover_test_modules(),
  eunit:test(TestModules, [verbose]),

  {ok, Analysis} = cover:analyse(campaigner_app, calls, line),

  ErlangSrcFile = filename:absname(
    "build/dev/erlang/campaigner_app/_gleam_artefacts/campaigner_app.erl"),
  {ok, Data} = file:read_file(ErlangSrcFile),
  ErlLines = binary:split(Data, <<"\n">>, [global]),
  LineMap = build_map(ErlLines, 1, 0, []),

  Mapped = lists:flatmap(fun({{_Mod, ErlLine}, Calls}) ->
    case lists:keyfind(ErlLine, 1, LineMap) of
      {_, GleamLine} -> [{GleamLine, Calls}];
      false -> []
    end
  end, Analysis),
  Sorted = lists:sort(Mapped),
  Deduped = dedupe(Sorted),

  TotalLines = length(Deduped),
  HitLines = length([1 || {_Line, Calls} <- Deduped, Calls > 0]),
  Percent = (HitLines / TotalLines) * 100,

  LcovPath = filename:absname("coverage.lcov"),
  {ok, Fd} = file:open(LcovPath, [write]),
  file:write(Fd, io_lib:format("SF:~s~n",
    [filename:absname("src/campaigner_app.gleam")])),
  lists:foreach(fun({Line, Calls}) ->
    file:write(Fd, io_lib:format("DA:~p,~p~n", [Line, Calls]))
  end, Deduped),
  file:write(Fd, io_lib:format("LF:~p~n", [TotalLines])),
  file:write(Fd, io_lib:format("LH:~p~n", [HitLines])),
  file:write(Fd, "end_of_record\n"),
  file:close(Fd),

  cover:stop(),

  io:format("~n=== Coverage Report ===~n"),
  io:format("Total lines: ~p~n", [TotalLines]),
  io:format("Hit lines: ~p~n", [HitLines]),
  io:format("Coverage: ~.2f%~n", [Percent]),

  case Percent >= 95.0 of
    true -> halt(0);
    false ->
      io:format("ERROR: Coverage ~.2f% is below 95% threshold~n", [Percent]),
      halt(1)
  end.

dedupe([]) -> [];
dedupe([{L, C1}, {L, _C2} | Rest]) ->
  dedupe([{L, C1} | Rest]);
dedupe([H | Rest]) ->
  [H | dedupe(Rest)].

build_map([], _ErlLine, _GleamLine, Acc) -> Acc;
build_map([Line | Rest], ErlLine, GleamLine, Acc) ->
  case re:run(Line, "-file\\(\"([^\"]+)\"\\s*,\\s*(\\d+)\\)",
      [{capture, all_but_first, list}]) of
    {match, [_File, LineNumStr]} ->
      NewGleamLine = list_to_integer(LineNumStr),
      build_map(Rest, ErlLine + 1, NewGleamLine, [{ErlLine, NewGleamLine} | Acc]);
    nomatch ->
      build_map(Rest, ErlLine + 1, GleamLine, [{ErlLine, GleamLine} | Acc])
  end.

discover_test_modules() ->
  {ok, Files} = file:list_dir("test"),
  TestFiles = [F || F <- Files,
    (filename:extension(F) =:= ".gleam" orelse filename:extension(F) =:= ".erl")],
  lists:map(fun(F) ->
    NoExt = filename:rootname(F),
    case filename:extension(F) of
      ".gleam" ->
        binary_to_atom(unicode:characters_to_binary(
          string:replace(NoExt, "/", "@", all)), utf8);
      _ ->
        list_to_atom(NoExt)
    end
  end, TestFiles).
