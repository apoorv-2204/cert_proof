defmodule Proofs.S09Q41RegistryExitTest do
  use ExUnit.Case, async: false

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 9 of 12 — Registry
  Question    : 41 of 60 (1 of 4 in section)
  External ID : z6CzVBScRLQ

  Question text:
    "What does happen to the registered processes if a Registry instance exits?"

    Response type: Multiple correct
    A. The registered processes continue to work, but all the entries in the
       registry will be lost.                                  <- candidate answered
    B. The registered processes continue to work. We can access registered items
       directly from ETS tables even after the registry has exited.

  Candidate : A  (marked Incorrect, 0/1)
  Reality   : NEITHER option is correct. VERDICT = FALSE (question is broken).

  Both options open with "The registered processes continue to work." They do
  not. `Registry.register/3` LINKS the caller to the registry's partition
  process — this is Elixir's own source, lib/elixir/lib/registry.ex:

      # Note that we write first to the pid_ets table because it will
      # always be able to do the cleanup. ...
      Process.link(pid_server)

  So when the Registry exits, that link fires and every registered process that
  is not trapping exits dies with it (test 1). Measured on 1.19.1:

      exit mode                    worker traps exits   worker alive after?
      Process.exit(reg, :kill)     false                NO
      Process.exit(reg, :kill)     true                 yes
      Supervisor.stop(reg)         false                NO
      Supervisor.stop(reg)         true                 yes

  Note it dies under an ORDERLY stop too — this is not an artifact of using
  :kill. Survival depends entirely on whether the registered process traps
  exits, which neither option mentions.

  On the half where the options differ, A is right and B is wrong: the Registry
  owns its ETS tables, so they are destroyed with it and the entries are lost
  (test 2). B's claim that you can still read them afterwards is impossible —
  `:ets.info/1` returns :undefined and `:ets.lookup/2` raises ArgumentError
  (test 3).

  So A is wrong on one clause and B is wrong on both. If a key must be chosen,
  A is strictly closer to the truth than B.
  """

  defp start_registry(name) do
    before = MapSet.new(:ets.all())
    {:ok, reg} = Registry.start_link(keys: :unique, name: name)
    {reg, MapSet.difference(MapSet.new(:ets.all()), before) |> Enum.to_list()}
  end

  defp spawn_registered(name, trap) do
    me = self()

    pid =
      spawn(fn ->
        if trap, do: Process.flag(:trap_exit, true)
        {:ok, _} = Registry.register(name, :k, :v)
        send(me, :registered)
        receive do: (:never -> :ok)
      end)

    assert_receive :registered, 1_000
    pid
  end

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  test "1. registered processes DO NOT survive — both options are wrong on this" do
    # Not trapping exits: the link from Registry.register/3 kills it.
    {reg, _} = start_registry(:reg_q41_a)
    worker = spawn_registered(:reg_q41_a, false)
    assert [{^worker, :v}] = Registry.lookup(:reg_q41_a, :k)

    Process.exit(reg, :kill)
    Process.sleep(200)

    refute Process.alive?(worker), "the registered process should have been killed by the link"

    # An ORDERLY stop kills it too — this is not a :kill artifact.
    {reg2, _} = start_registry(:reg_q41_b)
    worker2 = spawn_registered(:reg_q41_b, false)
    Supervisor.stop(reg2)
    Process.sleep(200)
    refute Process.alive?(worker2)

    # Only trapping exits saves it — a caveat neither option mentions.
    {reg3, _} = start_registry(:reg_q41_c)
    worker3 = spawn_registered(:reg_q41_c, true)
    Process.exit(reg3, :kill)
    Process.sleep(200)
    assert Process.alive?(worker3)
    Process.exit(worker3, :kill)
  end

  test "2. A's second clause is RIGHT — entries are lost with the ETS tables" do
    {reg, tables} = start_registry(:reg_q41_d)
    assert length(tables) > 0

    {:ok, _} = Registry.register(:reg_q41_d, :my_key, :some_value)
    assert [{_, :some_value}] = Registry.lookup(:reg_q41_d, :my_key)
    for t <- tables, do: refute(:ets.info(t) == :undefined)

    Process.exit(reg, :kill)
    Process.sleep(200)

    for t <- tables do
      assert :ets.info(t) == :undefined, "table #{inspect(t)} should be gone"
    end
  end

  test "3. B is FALSE — the ETS tables cannot be read after the Registry exits" do
    {reg, tables} = start_registry(:reg_q41_e)
    {:ok, _} = Registry.register(:reg_q41_e, :my_key, :some_value)

    Process.exit(reg, :kill)
    Process.sleep(200)

    for t <- tables do
      assert_raise ArgumentError, fn -> :ets.lookup(t, :my_key) end
    end

    assert :ets.info(:reg_q41_e) == :undefined
  end

  test "4. CONTROL: everything works while the Registry is alive" do
    {reg, tables} = start_registry(:reg_q41_f)
    worker = spawn_registered(:reg_q41_f, false)

    assert [{^worker, :v}] = Registry.lookup(:reg_q41_f, :k)
    assert Enum.all?(tables, &(:ets.info(&1) != :undefined))
    assert Process.alive?(worker)

    Supervisor.stop(reg)
  end
end
