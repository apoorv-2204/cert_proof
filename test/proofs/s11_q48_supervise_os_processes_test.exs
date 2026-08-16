defmodule Proofs.S11Q48.PortWrapper do
  @moduledoc "A BEAM process that owns a Port to an external OS process."
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: opts[:name])
  def os_pid(name), do: GenServer.call(name, :os_pid)

  @impl true
  def init(opts) do
    port =
      Port.open({:spawn_executable, System.find_executable("sleep")},
        [:binary, args: [opts[:seconds]]]
      )

    {:ok, port}
  end

  @impl true
  def handle_call(:os_pid, _from, port) do
    {:os_pid, os_pid} = Port.info(port, :os_pid)
    {:reply, os_pid, port}
  end
end

defmodule Proofs.S11Q48SuperviseOsProcessesTest do
  use ExUnit.Case, async: false

  alias Proofs.S11Q48.PortWrapper

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 11 of 12 — Supervisors
  Question    : 48 of 60 (2 of 10 in section)
  External ID : tdFFQIDPPe

  Question text:
    "Can a Supervisor supervise non-Elixir processes such as external system
     processes or operating system threads?"

    Response type: Multiple correct
    A. Yes, but the Supervisor will not be able to shutdown external process.
                                                    <- candidate selected, marked WRONG
    B. Yes, but the Supervisor will have a limited control over external process.
                                                    <- candidate selected, marked WRONG

  Candidate : A + B  (marked Incorrect, 0/1)
  Reality   : BOTH A AND B DESCRIBE THE MEASURED BEHAVIOUR.

  CAVEAT — only two options were captured from the results screen, and both are
  marked wrong with no grey "correct but unselected" tick visible. The key must
  therefore be an option that was not captured (most plausibly a "No"). Get the
  full option list before filing. What the tests below settle is the behaviour,
  so the dispute can be argued whatever the missing option says.

  Measured on 1.19.1 / OTP 28:

  1. An OS process cannot BE a supervisor child directly. A child's start
     function must return {:ok, pid} for a BEAM process; `System.cmd/3` returns
     {output, status}, and the supervisor refuses to start (test 1). In the
     strict sense, a Supervisor supervises BEAM processes only — which is the
     reading a "No" option would rely on.

  2. But the standard practice does work: a BEAM process owning a Port to an
     external executable supervises perfectly well (test 2). Under that reading
     the answer is "Yes, ..." — exactly how A and B open.

  3. And the control really is limited. Killing the supervisor kills the BEAM
     wrapper, but the external OS process SURVIVES as an orphan (test 3) — the
     well-known orphaned-port-process problem. That is precisely A's claim
     ("will not be able to shutdown external process") and B's ("limited
     control"), both confirmed.

  So on the substance A and B are accurate. If the key is a bare "No", it is
  defensible only on the pedantic reading in (1), and it contradicts the fact
  that supervising external processes through ports is ordinary Elixir practice.
  """

  # Distinctive durations so stray processes are identifiable, plus hard cleanup.
  defp reap(os_pid), do: System.cmd("kill", ["-9", "#{os_pid}"], stderr_to_stdout: true)

  defp os_alive?(os_pid) do
    {_out, code} = System.cmd("ps", ["-p", "#{os_pid}"], stderr_to_stdout: true)
    code == 0
  end

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  test "1. an OS process cannot be a supervisor child directly" do
    # start returns {output, status} from System.cmd/3, not {:ok, pid}.
    child = %{id: :os_proc, start: {System, :cmd, ["sleep", ["1"]]}}

    assert {:error, {:shutdown, {:failed_to_start_child, :os_proc, _}}} =
             Supervisor.start_link([child], strategy: :one_for_one)
  end

  test "2. a BEAM process owning a Port to an external program IS supervisable" do
    child = %{id: :w2, start: {PortWrapper, :start_link, [[name: :w2, seconds: "9871"]]}}
    {:ok, sup} = Supervisor.start_link([child], strategy: :one_for_one, name: __MODULE__.Sup2)

    os_pid = PortWrapper.os_pid(:w2)
    on_exit(fn -> reap(os_pid) end)

    assert is_integer(os_pid)
    assert os_alive?(os_pid), "the external OS process should be running"
    assert Process.alive?(sup)

    Supervisor.stop(sup)
  end

  test "3. A and B are TRUE — killing the supervisor orphans the OS process" do
    child = %{id: :w3, start: {PortWrapper, :start_link, [[name: :w3, seconds: "9872"]]}}
    {:ok, sup} = Supervisor.start_link([child], strategy: :one_for_one, name: __MODULE__.Sup3)

    os_pid = PortWrapper.os_pid(:w3)
    on_exit(fn -> reap(os_pid) end)
    assert os_alive?(os_pid)

    # Take down the whole supervision tree.
    Process.exit(sup, :kill)
    Process.sleep(500)

    refute Process.alive?(sup)

    # The external process outlives it: the Supervisor could not shut it down.
    assert os_alive?(os_pid),
           "the external OS process should have survived — this is A's and B's claim"

    reap(os_pid)
    Process.sleep(200)
    refute os_alive?(os_pid), "sanity check: it dies when something actually kills it"
  end

  test "4. even an ORDERLY shutdown leaves the external process running" do
    child = %{id: :w4, start: {PortWrapper, :start_link, [[name: :w4, seconds: "9873"]]}}
    {:ok, sup} = Supervisor.start_link([child], strategy: :one_for_one, name: __MODULE__.Sup4)

    os_pid = PortWrapper.os_pid(:w4)
    on_exit(fn -> reap(os_pid) end)

    Supervisor.stop(sup)
    Process.sleep(500)

    refute Process.alive?(sup)
    assert os_alive?(os_pid), "orderly shutdown does not reap the OS process either"
  end
end
