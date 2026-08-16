# capture_log: true keeps the expected crash reports (killed supervisors,
# Registry partitions, linked GenServers) out of a passing run's output.
# They are still captured and ARE printed if a test fails.
ExUnit.start(capture_log: true)
