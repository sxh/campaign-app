#!/bin/bash
set -e

ERL_TOP="/usr/local/Cellar/erlang/28.4.2/lib/erlang"
TOOLS_EBIN="$ERL_TOP/lib/tools-4.1.4/ebin"
BUILD_DIR="build/dev/erlang"
PWD=$(pwd)

# Collect ebin paths as an array to avoid quoting issues
EBIN_ARGS=()
for app in "$BUILD_DIR"/*/ebin; do
  EBIN_ARGS+=(-pa "$app")
done

erl -noshell -boot start_clean \
  -pa "$TOOLS_EBIN" \
  "${EBIN_ARGS[@]}" \
  -eval '
    LcovPath = "'"$PWD"'/coverage.lcov",
    cover:start(),
    case cover:compile_beam(campaigner_app) of
      {ok, _} -> ok;
      {error, R} -> io:format("Compile error: ~p~n", [R]), halt(1)
    end,
    gleeunit:main(),
    {ok, Analysis} = cover:analyse(campaigner_app, calls, line),
    {ok, Source} = file:read_file("'"$PWD"'/src/campaigner_app.gleam"),
    SourceLines = binary:split(Source, <<"\n">>, [global]),
    TotalLines = length(SourceLines),
    UncoveredLines = length([1 || {_, {_, 0}} <- Analysis]),
    Percent = ((TotalLines - UncoveredLines) / TotalLines) * 100,
    io:format("~nCoverage: ~.2f%~n", [Percent]),
    {ok, Fd} = file:open(LcovPath, [write]),
    file:write(Fd, io_lib:format("SF:~s~n", ["'"$PWD"'/src/campaigner_app.gleam"])),
    file:write(Fd, io_lib:format("LF:~p~n", [TotalLines])),
    file:write(Fd, io_lib:format("LH:~p~n", [TotalLines - UncoveredLines])),
    lists:foreach(fun({Line, {Calls, _}}) ->
      file:write(Fd, io_lib:format("DA:~p,~p~n", [Line, Calls]))
    end, lists:sort(Analysis)),
    file:write(Fd, "end_of_record~n"),
    file:close(Fd),
    cover:stop(),
    halt()
' 2>&1

echo "Coverage report written to $PWD/coverage.lcov"
