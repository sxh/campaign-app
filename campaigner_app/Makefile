.PHONY: test coverage coverage-html check-coverage lint warnings

test:
	@gleam test

lint:
	@gleam format --check src test

warnings:
	@# gleam check returns 0 even with warnings, so we grep for the warning pattern
	@gleam check 2>&1 | tee /tmp/gleam_check_output
	@! grep -q "warning:" /tmp/gleam_check_output

coverage:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		Modules = [campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@services@dashboard_service, campaigner@infrastructure@simplifile_adapter, campaigner@infrastructure@fake_file_system, campaigner@infrastructure@stdout_logger, campaigner@infrastructure@gemini_cli_adapter, campaigner@config, campaigner@config@defaults, campaigner@ports@chat_engine, campaigner@ports@file_system, campaigner@ports@logger], \
		{Cov, Uncov} = lists:foldl(fun(M, {AccC1, AccU1}) -> \
			case cover:analyse(M, coverage, line) of \
				{ok, Lines} -> \
					lists:foldl(fun({{_, _}, {C, _}}, {AC, AU}) -> \
						{AC + C, AU + (1 - C)} \
					end, {AccC1, AccU1}, Lines); \
				_ -> {AccC1, AccU1} \
			end \
		end, {0, 0}, Modules), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("~nProject Coverage (Logic Only):~n"), \
		io:format("  Covered:   ~p lines~n", [Cov]), \
		io:format("  Uncovered: ~p lines~n", [Uncov]), \
		io:format("  Total:     ~p lines~n", [Cov + Uncov]), \
		io:format("  Percent:   ~p%~n", [Percent]), \
		init:stop().'

check-coverage: lint warnings
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		Modules = [campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@services@dashboard_service, campaigner@infrastructure@simplifile_adapter, campaigner@infrastructure@fake_file_system, campaigner@infrastructure@stdout_logger, campaigner@infrastructure@gemini_cli_adapter, campaigner@config, campaigner@config@defaults, campaigner@ports@chat_engine, campaigner@ports@file_system, campaigner@ports@logger], \
		{Cov, Uncov} = lists:foldl(fun(M, {AccC1, AccU1}) -> \
			case cover:analyse(M, coverage, line) of \
				{ok, Lines} -> \
					lists:foldl(fun({{_, _}, {C, _}}, {AC, AU}) -> \
						{AC + C, AU + (1 - C)} \
					end, {AccC1, AccU1}, Lines); \
				_ -> {AccC1, AccU1} \
			end \
		end, {0, 0}, Modules), \
		Percent = case (Cov + Uncov) of 0 -> 100; _ -> (Cov * 100) div (Cov + Uncov) end, \
		io:format("Project Coverage: ~p%~n", [Percent]), \
		case Percent >= 97 of \
			true -> init:stop(); \
			false ->  \
				io:format("ERROR: Project coverage is below 97% (Current: ~p%)~n", [Percent]), \
				halt(1) \
		end.'

coverage-html:
	@erl -pa build/dev/erlang/*/ebin -noshell -eval ' \
		_ = cover:start(), \
		_ = cover:compile_beam_directory("build/dev/erlang/campaigner_app/ebin"), \
		_ = eunit:test(campaigner_app_test), \
		_ = [cover:analyse_to_file(M, [html]) || M <- [campaigner_app, campaigner@vault, campaigner@web@views, campaigner@web@router, campaigner@services@dashboard_service, campaigner@infrastructure@simplifile_adapter, campaigner@infrastructure@fake_file_system, campaigner@infrastructure@stdout_logger, campaigner@infrastructure@gemini_cli_adapter, campaigner@config, campaigner@config@defaults, campaigner@system, campaigner@ports@chat_engine, campaigner@ports@file_system, campaigner@ports@logger]], \
		io:format("~nHTML reports generated.~n"), \
		init:stop().'
