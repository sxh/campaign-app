.PHONY: test coverage coverage-html check-coverage

test:
	@gleam test

coverage:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		{ok, L1} = cover:analyse(campaigner_app, coverage, line), \
		{ok, L2} = cover:analyse(campaigner@vault, coverage, line), \
		{ok, L3} = cover:analyse(campaigner@web@views, coverage, line), \
		Lines = L1 ++ L2 ++ L3, \
		{Cov, Uncov} = lists:foldl(fun({{M, L}, {C, _}}, {AccC, AccU}) -> \
			Exclude = (M =:= campaigner_app andalso L < 23), \
			case Exclude of \
				true -> {AccC, AccU}; \
				false -> {AccC + C, AccU + (1 - C)} \
			end \
		end, {0, 0}, Lines), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("~nProject Coverage:~n"), \
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
		{ok, L1} = cover:analyse(campaigner_app, coverage, line), \
		{ok, L2} = cover:analyse(campaigner@vault, coverage, line), \
		{ok, L3} = cover:analyse(campaigner@web@views, coverage, line), \
		Lines = L1 ++ L2 ++ L3, \
		{Cov, Uncov} = lists:foldl(fun({{M, L}, {C, _}}, {AccC, AccU}) -> \
			Exclude = (M =:= campaigner_app andalso L < 23), \
			case Exclude of \
				true -> {AccC, AccU}; \
				false -> {AccC + C, AccU + (1 - C)} \
			end \
		end, {0, 0}, Lines), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("Project Coverage: ~p%~n", [Percent]), \
		case Percent >= 71 of \
			true -> init:stop(); \
			false ->  \
				io:format("ERROR: Project coverage is below 71% (Current: ~p%)~n", [Percent]), \
				halt(1) \
		end.'

coverage-html:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		_ = cover:analyse_to_file(campaigner_app, [html]), \
		_ = cover:analyse_to_file(campaigner@vault, [html]), \
		_ = cover:analyse_to_file(campaigner@web@views, [html]), \
		io:format("~nHTML reports generated.~n"), \
		init:stop().'
