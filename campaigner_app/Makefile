.PHONY: test coverage coverage-html check-coverage

test:
	@gleam test

coverage:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		Modules = [campaigner_app, campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@config], \
		{Cov, Uncov} = lists:foldl(fun(M, {AccC, AccU}) -> \
			case cover:analyse(M, coverage, line) of \
				{ok, Lines} -> \
					lists:foldl(fun({{Mod, L}, {C, _}}, {AC, AU}) -> \
						Exclude = (Mod =:= campaigner_app), \
						case Exclude of \
							true -> {AC, AU}; \
							false -> {AC + C, AU + (1 - C)} \
						end \
					end, {AccC, AccU}, Lines); \
				_ -> {AccC, AccU} \
			end \
		end, {0, 0}, Modules), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("~nProject Coverage (Logic Only):~n"), \
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
		Modules = [campaigner_app, campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@config], \
		{Cov, Uncov} = lists:foldl(fun(M, {AccC, AccU}) -> \
			case cover:analyse(M, coverage, line) of \
				{ok, Lines} -> \
					lists:foldl(fun({{Mod, L}, {C, _}}, {AC, AU}) -> \
						Exclude = (Mod =:= campaigner_app), \
						case Exclude of \
							true -> {AC, AU}; \
							false -> {AC + C, AU + (1 - C)} \
						end \
					end, {AccC, AccU}, Lines); \
				_ -> {AccC, AccU} \
			end \
		end, {0, 0}, Modules), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("Project Coverage: ~p%~n", [Percent]), \
		case Percent >= 80 of \
			true -> init:stop(); \
			false ->  \
				io:format("ERROR: Project coverage is below 80% (Current: ~p%)~n", [Percent]), \
				halt(1) \
		end.'

coverage-html:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		_ = [cover:analyse_to_file(M, [html]) || M <- [campaigner_app, campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@config]], \
		io:format("~nHTML reports generated.~n"), \
		init:stop().'
