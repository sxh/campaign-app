#!/usr/bin/env escript
%%! -boot start_clean -pa build/dev/erlang/campaigner_app/ebin -pa build/dev/erlang/gleam_stdlib/ebin -pa build/dev/erlang/gleam_erlang/ebin -pa build/dev/erlang/lustre/ebin -pa build/dev/erlang/gleam_json/ebin -pa build/dev/erlang/gleam_otp/ebin -pa build/dev/erlang/houdini/ebin -pa build/dev/erlang/gleeunit/ebin -pa build/dev/erlang/gleam_javascript/ebin

main(_) ->
  cover:start(),

  %% electron_preload is JavaScript-only (Erlang stubs panic), so exclude it
  SourceModules = [campaigner_app, opencode_session, obsidian_vault],
  lists:foreach(fun(M) ->
    {ok, _} = cover:compile_beam(M)
  end, SourceModules),

  TestModules = discover_test_modules(),
  eunit:test(TestModules, [verbose]),

  LcovPath = filename:absname("coverage.lcov"),
  {ok, Fd} = file:open(LcovPath, [write]),

  Results = lists:map(fun(Mod) ->
    {ok, Analysis} = cover:analyse(Mod, calls, line),
    ErlSrcFile = filename:absname(
      "build/dev/erlang/campaigner_app/_gleam_artefacts/" ++ atom_to_list(Mod) ++ ".erl"),
    case file:read_file(ErlSrcFile) of
      {ok, Data} ->
        ErlLines = binary:split(Data, <<"\n">>, [global]),
        LineMap = build_map(ErlLines, 1, 0, []),
        Mapped = lists:flatmap(fun({{_Mod2, ErlLine}, Calls}) ->
          case lists:keyfind(ErlLine, 1, LineMap) of
            {_, GleamLine} -> [{GleamLine, Calls}];
            false -> []
          end
        end, Analysis),
        Sorted = lists:sort(Mapped),
        Deduped = dedupe(Sorted),
        TotalLines = length(Deduped),
        HitLines = length([1 || {_Line, Calls} <- Deduped, Calls > 0]),
        GleamSrc = filename:absname("src/" ++ atom_to_list(Mod) ++ ".gleam"),
        file:write(Fd, io_lib:format("SF:~s~n", [GleamSrc])),
        lists:foreach(fun({Line, Calls}) ->
          file:write(Fd, io_lib:format("DA:~p,~p~n", [Line, Calls]))
        end, Deduped),
        file:write(Fd, io_lib:format("LF:~p~n", [TotalLines])),
        file:write(Fd, io_lib:format("LH:~p~n", [HitLines])),
        file:write(Fd, "end_of_record\n"),
        io:format("~n--- ~s ---~n", [GleamSrc]),
        io:format("Total lines: ~p~n", [TotalLines]),
        io:format("Hit lines: ~p~n", [HitLines]),
        Pct = (HitLines / TotalLines) * 100,
        io:format("Coverage: ~.2f~n", [Pct]),
        {TotalLines, HitLines};
      {error, _} ->
        io:format("~n--- ~s ---~n", [filename:absname("src/" ++ atom_to_list(Mod) ++ ".gleam")]),
        io:format("No Erlang source found, skipping line mapping~n", []),
        {0, 0}
    end
  end, SourceModules),

  file:close(Fd),
  cover:stop(),

  TotalAll = lists:sum([T || {T, _} <- Results]),
  HitAll = lists:sum([H || {_, H} <- Results]),
  PercentAll = (HitAll / TotalAll) * 100,
  io:format("~n=== Overall Coverage ===~n"),
  io:format("Total lines: ~p~n", [TotalAll]),
  io:format("Hit lines: ~p~n", [HitAll]),
  io:format("Coverage: ~.2f~n", [PercentAll]),

  case PercentAll >= 95.0 of
    true -> halt(0);
    false ->
      io:format("ERROR: Coverage ~.2f is below 95~n", [PercentAll]),
      halt(1)
  end.

dedupe([]) -> [];
dedupe([{L, C1}, {L, C2} | Rest]) ->
  dedupe([{L, erlang:max(C1, C2)} | Rest]);
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
