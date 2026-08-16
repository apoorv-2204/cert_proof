defmodule Proofs.S02Q05NodeSpawnLinkDeadNodeTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 2 of 12 — Distribution
  Question    : 5 of 60 (3 of 3 in section)
  External ID : FzhHRqYbAy

  Question text:
    "Given the node started with the following command: `iex --sname test@localhost`.
     What will the `Node.spawn_link/2` call return if the other node is stopped
     or does not exist?"

    Response type: Multiple correct
    A. It will return an error.
    B. it will return a useless PID and a warning will be printed.
                                              <- candidate answered, marked WRONG

  Candidate : B  (marked Incorrect, 0/1)
  Reality   : B is CORRECT. VERDICT = FALSE (the exam is wrong).

  Option B is almost a verbatim quote of the Erlang documentation for
  `spawn_link/2`: "If Node does not exist, a useless pid is returned and an exit
  signal with reason noconnection is sent to the calling process."

  Both halves of B are observable:
    * a pid IS returned (test 1) — so A, "it will return an error", is false:
      there is no error tuple, no raise, no throw;
    * a warning IS printed (test 2):
      `[warning] ** Can not start :erlang::apply,[...] ([:link]) on :ghost@localhost **`

  The detail that makes this look like an error in practice: the caller is
  LINKED, so it also receives an exit signal `:noconnection` (test 3). In a plain
  iex session that kills the shell and IEx restarts it, printing
  `** (EXIT from #PID<...>) shell process exited with reason: no connection`.
  That crash is the *aftermath* of the call, not its return value — the question
  asks what the call RETURNS.
  """

  @ghost :"ghost@localhost"

  setup do
    unless Node.alive?() do
      {:ok, _} = Node.start(:"cert_proof_test@localhost", :shortnames)
    end

    Process.flag(:trap_exit, true)
    :ok
  end

  test "1. it returns a PID, not an error — option A is false" do
    capture_log(fn ->
      returned = Node.spawn_link(@ghost, fn -> :never_runs end)

      # PROOF A IS FALSE: the return value is a plain pid.
      assert is_pid(returned)
      refute match?({:error, _}, returned)
      refute match?(:error, returned)

      # And the ghost node genuinely is not connected.
      refute @ghost in Node.list()
    end)
  end

  test "2. a warning IS printed — the second half of option B" do
    log =
      capture_log(fn ->
        Node.spawn_link(@ghost, fn -> :never_runs end)
        # give the runtime a moment to emit the async warning
        assert_receive {:EXIT, _pid, :noconnection}, 2_000
      end)

    assert log =~ "[warning]"
    assert log =~ "Can not start"
    assert log =~ "ghost@localhost"
  end

  test "3. the pid is 'useless' — the caller gets a :noconnection exit signal" do
    capture_log(fn ->
      returned = Node.spawn_link(@ghost, fn -> :never_runs end)

      # The link fires: this is what kills an un-trapped caller (e.g. the iex shell).
      assert_receive {:EXIT, ^returned, :noconnection}, 2_000

      # Nothing usable is on the other end of that pid.
      refute Process.alive?(returned)
    end)
  end

  test "4. CONTROL: spawn_link to the LOCAL live node works normally" do
    parent = self()

    pid = Node.spawn_link(Node.self(), fn -> send(parent, :ran) end)

    assert is_pid(pid)
    assert_receive :ran, 2_000
    refute_receive {:EXIT, ^pid, :noconnection}, 200
  end
end
