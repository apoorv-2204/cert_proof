defmodule Proofs.S11Q54.AlwaysFailsInit do
  @moduledoc "A GenServer child whose init/1 always raises."
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init(_) do
    send(:persistent_term.get({Proofs.S11Q54SupervisorInitFailureTest, :pid}), :init_called)
    raise "boom in init/1"
  end
end

defmodule Proofs.S11Q54.HealthyChild do
  @moduledoc "A well-behaved child, used as the control case."
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    send(:persistent_term.get({Proofs.S11Q54SupervisorInitFailureTest, :pid}), :init_called)
    {:ok, %{}}
  end
end

defmodule Proofs.S11Q54.FailsInitAfterFirst do
  @moduledoc "Starts cleanly once; every later init/1 (i.e. every restart) raises."
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_) do
    test_pid = :persistent_term.get({Proofs.S11Q54SupervisorInitFailureTest, :pid})
    send(test_pid, :init_called)

    case :counters.get(:persistent_term.get({Proofs.S11Q54SupervisorInitFailureTest, :ctr}), 1) do
      0 ->
        :counters.add(:persistent_term.get({Proofs.S11Q54SupervisorInitFailureTest, :ctr}), 1, 1)
        {:ok, %{}}

      _ ->
        raise "boom on restart"
    end
  end
end

defmodule Proofs.S11Q54SupervisorInitFailureTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias Proofs.S11Q54.{AlwaysFailsInit, FailsInitAfterFirst, HealthyChild}

  @moduledoc """
  Exam      : Elixir Online Advanced Exam 2025
  Section   : 11 of 12 — Supervisors
  Question  : 54 of 60 (8 of 10 in section)
  Question ID / Source ID : uMmsvUudbZp
  External ID             : DYoKKwfhjM
  Response ID             : 2E8HmG--f_0

  Question text:
    "Given the Supervisor running with `strategy: :one_for_one`. Its child
     process is a GenServer. The GenServer is started by a Supervisor, but
     GenServer's `init/1` callback raised an error. Which of the following
     statements describes what will happen to Supervisor?"

    A. The Supervisor will then be terminated as well.            <- candidate answered
    B. The Supervisor will attempt to restart the child process
       according to its restart strategy.                         <- exam marked correct

  Exam says : B
  Candidate : A  (marked Incorrect, 0/1)
  Reality   : A is correct. VERDICT = FALSE (the exam's marked answer is wrong).

  Why: the question states the child "is started by a Supervisor" and init/1
  raised. That is start-up. During supervisor start-up a child that fails to
  start is NOT restarted — the supervisor aborts, terminates any already-started
  children, and itself exits with
  `{:shutdown, {:failed_to_start_child, child_id, reason}}`. The restart strategy
  is never consulted, so B does not happen at all.

  And even under the most generous reading of B — a child that crashes *after*
  a successful start, whose init/1 then fails on restart — the supervisor still
  ends up terminated once restart intensity is exceeded (test 3). So A is the
  correct answer under BOTH readings of the question; B is correct under neither.
  """

  setup do
    :persistent_term.put({__MODULE__, :pid}, self())
    :persistent_term.put({__MODULE__, :ctr}, :counters.new(1, []))
    Process.flag(:trap_exit, true)
    :ok
  end

  test "1. init/1 failing at start-up terminates the Supervisor — it never restarts the child" do
    capture_log(fn ->
      result =
        Supervisor.start_link([AlwaysFailsInit],
          strategy: :one_for_one,
          name: __MODULE__.Sup1
        )

      # The supervisor does not start at all. This is option A.
      assert {:error, {:shutdown, {:failed_to_start_child, AlwaysFailsInit, reason}}} = result
      assert {%RuntimeError{message: "boom in init/1"}, _stacktrace} = reason
    end)

    # PROOF OF A: there is no live Supervisor afterwards.
    assert Process.whereis(__MODULE__.Sup1) == nil

    # PROOF THAT B IS FALSE: init/1 ran exactly ONCE. No restart was attempted.
    assert_received :init_called
    refute_received :init_called
  end

  test "2. CONTROL: a healthy child does start, proving the setup is valid" do
    assert {:ok, sup} =
             Supervisor.start_link([HealthyChild], strategy: :one_for_one, name: __MODULE__.Sup2)

    assert Process.alive?(sup)
    assert is_pid(Process.whereis(HealthyChild))
    assert_received :init_called

    Supervisor.stop(sup)
  end

  test "3. Even the generous reading of B ends with the Supervisor terminated" do
    {:ok, sup} =
      Supervisor.start_link([FailsInitAfterFirst], strategy: :one_for_one, name: __MODULE__.Sup3)

    assert Process.alive?(sup)
    assert_received :init_called
    child = Process.whereis(FailsInitAfterFirst)

    capture_log(fn ->
      # Kill the child. NOW the supervisor really does consult its restart
      # strategy — but every restart's init/1 raises.
      Process.exit(child, :kill)
      assert_receive {:EXIT, ^sup, :shutdown}, 5_000
    end)

    # The supervisor attempted restarts (B, briefly) and then died anyway (A).
    refute Process.alive?(sup)
    assert Process.whereis(__MODULE__.Sup3) == nil
  end
end
