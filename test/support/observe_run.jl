# Runs `f` in an empty directory and returns its value together with everything
# it printed, logged and wrote.
function _observe_run(f)
	mktempdir() do directory
		logger = Test.TestLogger(min_level = Logging.Debug)
		out_path, err_path = joinpath(directory, "stdout"), joinpath(directory, "stderr")
		work = mkdir(joinpath(directory, "work"))
		value = open(out_path, "w") do out
			open(err_path, "w") do err
				redirect_stdout(out) do
					redirect_stderr(err) do
						cd(() -> Logging.with_logger(f, logger), work)
					end
				end
			end
		end
		return (; value, printed = read(out_path, String) * read(err_path, String),
			logs = logger.logs, files = readdir(work))
	end
end
