.PHONY: test coverage coverage-html check-coverage

test:
	@gleam test

coverage:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		{ok, Lines} = cover:analyse(campaigner_app, coverage, line), \
		{Cov, Uncov} = lists:foldl(fun({{_, L}, {C, _}}, {AccC, AccU}) -> \
			case L >= 46 of \
				true -> {AccC + C, AccU + (1 - C)}; \
				false -> {AccC, AccU} \
			end \
		end, {0, 0}, Lines), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("~nTestable Coverage (Line 46+):~n"), \
		io:format("  Covered:   ~p lines~n", [Cov]), \
		io:format("  Uncovered: ~p lines~n", [Uncov]), \
		io:format("  Total:     ~p lines~n", [Cov + Uncov]), \
		io:format("  Percent:   ~p%~n", [Percent]), \
		init:stop().'

check-coverage:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		{ok, Lines} = cover:analyse(campaigner_app, coverage, line), \
		{Cov, Uncov} = lists:foldl(fun({{_, L}, {C, _}}, {AccC, AccU}) -> \
			case L >= 46 of \
				true -> {AccC + C, AccU + (1 - C)}; \
				false -> {AccC, AccU} \
			end \
		end, {0, 0}, Lines), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("Testable Coverage: ~p%~n", [Percent]), \
		case Percent >= 74 of \
			true -> init:stop(); \
			false ->  \
				io:format("ERROR: Testable coverage is below 74% (Current: ~p%)~n", [Percent]), \
				halt(1) \
		end.'

coverage-html:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		{ok, File} = cover:analyse_to_file(campaigner_app, [html]), \
		io:format("~nHTML report generated: ~s~n", [File]), \
		init:stop().'
