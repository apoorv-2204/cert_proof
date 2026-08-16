defmodule Proofs.S04Q14.Child do
  @moduledoc "GenServer with a cleanup terminate/2; trapping is configurable."
  use GenServer

  def start_link({test, trap}), do: GenServer.start_link(__MODULE__, {test, trap})

  @impl true
  def init({test, trap}) do
    if trap, do: Process.flag(:trap_exit, true)
    send(test, {:up, self()})
    {:ok, test}
  end

  @impl true
  def terminate(reason, test) do
    send(test, {:terminate_ran, reason})
    :ok
  end
end

defmodule Proofs.S04Q14.Crasher do
  @moduledoc "Disposable child used to burn through the supervisor's restart intensity."
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_), do: {:ok, %{}}
end

defmodule Proofs.S04Q14SupervisorAbnormalTerminateTest do
  use ExUnit.Case, async: false

  alias Proofs.S04Q14.{Child, Crasher}

  @moduledoc """
  Exam      : Elixir Online Advanced Exam 2025
  Section     : 4 of 12 — Gen Server
  Question    : 14 of 60 (2 of 11 in section)
  External ID : bFxIfcxBIY

  Question text:
    "Given a Supervisor. The child process is a GenServer which has a
     terminate/2 callback function that performs some cleanup. GenServer is
     configured to trap exits with `Process.flag(:trap_exits, true)` in its
     init/1 callback. If the supervisor terminated abnormally, will the
     GenServer's terminate/2 be invoked?"

    Response type: Multiple correct
    A. No. If the Supervisor is terminated abnormally, all of the child
       processes are terminated immediately.                    <- candidate answered
    B. Depends on the strategy of the Supervisor.

  Candidate : A  (marked Incorrect, 0/1)
  Reality   : NEITHER A NOR B IS CORRECT. VERDICT = FALSE (question is broken).

  The true answer is "Yes — terminate/2 IS invoked", and what decides it is the
  child trapping exits, never the supervisor's strategy.

  Three independent defects:

  1. The code in the question does not run. The flag is `:trap_exit`, not
     `:trap_exits`. `Process.flag(:trap_exits, true)` raises ArgumentError
     ("invalid process flag"), so init/1 would crash and the child would never
     start at all (test 1). Taken literally, the premise is impossible.

  2. Option A is false. With exits trapped, a supervisor killed abnormally
     leaves the child receiving `{:EXIT, sup, :killed}`; gen_server treats a
     parent exit by calling terminate/2, which runs the cleanup (test 2).
     Children are NOT "terminated immediately".

  3. Option B is false. The restart strategy is irrelevant here — it governs how
     children are restarted when a CHILD dies, not what happens when the
     SUPERVISOR dies. :one_for_one, :one_for_all and :rest_for_one behave
     identically (tests 3 and 4). The deciding variable is trap_exit (test 4).
  """

  @strategies [:one_for_one, :one_for_all, :rest_for_one]

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  defp start_sup(strategy, trap) do
    test = self()

    {:ok, sup} =
      Supervisor.start_link(
        [%{id: Child, start: {Child, :start_link, [{test, trap}]}}],
        strategy: strategy
      )

    assert_receive {:up, _child}, 1_000
    sup
  end

  test "1. the question's own code raises — :trap_exits is not a valid process flag" do
    assert_raise ArgumentError, fn -> Process.flag(:trap_exits, true) end

    # The real flag, for contrast, works fine.
    assert is_boolean(Process.flag(:trap_exit, true))
  end

  test "2. supervisor killed abnormally + child traps exits => terminate/2 RUNS (A is false)" do
    sup = start_sup(:one_for_one, true)

    Process.exit(sup, :kill)

    assert_receive {:terminate_ran, :killed}, 1_000
    refute Process.alive?(sup)
  end

  test "3. identical under EVERY strategy => it does not depend on strategy (B is false)" do
    for strategy <- @strategies do
      sup = start_sup(strategy, true)
      Process.exit(sup, :kill)

      assert_receive {:terminate_ran, :killed}, 1_000, "terminate/2 did not run for #{strategy}"
    end
  end

  test "4. the deciding factor is trap_exit, not strategy" do
    for strategy <- @strategies do
      # trapping -> cleanup runs
      sup = start_sup(strategy, true)
      Process.exit(sup, :kill)
      assert_receive {:terminate_ran, :killed}, 1_000

      # not trapping -> cleanup is skipped, under the very same strategy
      sup2 = start_sup(strategy, false)
      Process.exit(sup2, :kill)
      refute_receive {:terminate_ran, _}, 300
    end
  end

  test "5. the other abnormal death (restart intensity exceeded) also runs terminate/2" do
    test = self()

    {:ok, sup} =
      Supervisor.start_link(
        [
          %{id: Child, start: {Child, :start_link, [{test, true}]}},
          %{id: Crasher, start: {Crasher, :start_link, [nil]}}
        ],
        strategy: :one_for_one
      )

    assert_receive {:up, _}, 1_000

    # Burn past the default intensity of 3 restarts / 5 seconds.
    for _ <- 1..5 do
      if pid = Process.whereis(Crasher), do: Process.exit(pid, :kill)
      Process.sleep(30)
    end

    # Supervisor gave up and died abnormally; the child still got to clean up.
    assert_receive {:terminate_ran, :shutdown}, 2_000
    refute Process.alive?(sup)
  end
end
