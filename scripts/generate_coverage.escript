#!/usr/bin/env escript
%%! -pa build/dev/erlang/campaigner_app/ebin -pa build/dev/erlang/gleam_stdlib/ebin -pa build/dev/erlang/gleam_erlang/ebin -pa build/dev/erlang/lustre/ebin -pa build/dev/erlang/gleam_json/ebin -pa build/dev/erlang/gleam_otp/ebin -pa build/dev/erlang/houdini/ebin -pa build/dev/erlang/gleeunit/ebin -pa build/dev/erlang/gleam_javascript/ebin

main(_) ->
  cover:start(),
  Module = campaigner_app,
  {ok, _} = cover:compile_beam(Module),
  {ok, _} = cover:compile_beam(campaigner_app@@main),
  {ok, _} = cover:compile_beam(campaigner_app_test),

  {ok, _} = gleeunit:main(),

  {ok, Analysis} = cover:analyse(Module, calls, line),

  AbsolutePath = filename:absname("src/campaigner_app.gleam"),
  LcowContent = lcov_entry(Module, AbsolutePath, Analysis),

  file:write_file("coverage.lcov", LcowContent),
  io:format("Coverage report written to coverage.lcov~n"),

  cover:stop().

lcov_entry(Module, SourceFile, Analysis) ->
  SF = io_lib:format("SF:~s~n", [SourceFile]),
  FnEntries = [],
  DaEntries = lists:foldl(fun
    ({Line, {_Calls, 0}}, Acc) -> [io_lib:format("DA:~p,0~n", [Line]) | Acc];
    ({Line, {Calls, _}}, Acc) -> [io_lib:format("DA:~p,~p~n", [Line, Calls]) | Acc]
  end, [], Analysis),
  LH = length([1 || {_, {_, 0}} <- Analysis]),
  LF = length(Analysis),
  EndLine = io_lib:format("end_of_record~n", []),
  [SF, FnEntries, DaEntries, io_lib:format("LH:~p~n", [LH]),
   io_lib:format("LF:~p~n", [LF]), EndLine].
