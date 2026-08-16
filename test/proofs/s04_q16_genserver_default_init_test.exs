defmodule Proofs.S04Q16GenserverDefaultInitTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 4 of 12 — Gen Server
  Question    : 16 of 60 (4 of 11 in section)
  External ID : ByEUMyrqgk

  Question text:
    defmodule ExampleServer do
      use GenServer

      def start_link do
        GenServer.start_link(__MODULE__, nil)
      end
    end

    "What will the ExampleServer.start_link() call return?"

    Response type: Multiple correct
    A. It will return {:ok, nil}.
    B. It will return {:ok, pid}, but server will crash immediately.  <- candidate answered
    C. It will return an error because the init/1 callback is not implemented.

  Candidate : B  (marked Incorrect, 0/1)
  Reality   : it returns {:ok, pid} and the server does NOT crash.
              VERDICT = FALSE (no option is correct).

  `use GenServer` injects a default `init/1` that returns `{:ok, init_arg}`, so
  the server starts normally with state `nil` and keeps running (test 1).

    * A is wrong — the return is {:ok, pid}, not {:ok, nil}. `nil` is the
      server's STATE, not the return value.
    * B is half right and half wrong — {:ok, pid} is correct, "crashes
      immediately" is not. The process is still alive afterwards (test 2).
    * C is wrong — there is no error; the default init/1 makes it work (test 3).

  The trap: the compiler DOES emit a warning, "function init/1 required by
  behaviour GenServer is not implemented (in module ExampleServer). We will
  inject a default implementation for now" (test 3). Reading only the first half
  of that warning makes C look right — but it is a warning, not an error, and it
  says outright that a default is injected.

  Since B is the only option that gets the return value right, it is the closest
  of the three; but as written, none is correct.
  """

  @src """
  defmodule Proofs.S04Q16.ExampleServer do
    use GenServer

    def start_link do
      GenServer.start_link(__MODULE__, nil)
    end
  end
  """

  setup_all do
    warning = capture_io(:stderr, fn -> Code.compile_string(@src) end)
    {:ok, warning: warning}
  end

  test "1. it returns {:ok, pid} — a live process, with state nil" do
    assert {:ok, pid} = Proofs.S04Q16.ExampleServer.start_link()
    assert is_pid(pid)

    # `nil` is the STATE, which is what option A confuses for the return value.
    assert :sys.get_state(pid) == nil

    GenServer.stop(pid)
  end

  test "2. B is FALSE — the server does not crash" do
    {:ok, pid} = Proofs.S04Q16.ExampleServer.start_link()
    ref = Process.monitor(pid)

    refute_receive {:DOWN, ^ref, :process, ^pid, _}, 500
    assert Process.alive?(pid)

    # It is a working GenServer, not a dying one.
    assert :sys.get_state(pid) == nil
    GenServer.stop(pid)
  end

  test "3. C is FALSE — a WARNING is emitted, not an error", %{warning: warning} do
    assert warning =~ "function init/1 required by behaviour GenServer is not implemented"
    # ...and the same warning states the remedy that makes the code work:
    assert warning =~ "We will inject a default implementation for now"

    # Proof it is not an error: the module compiled and runs.
    assert function_exported?(Proofs.S04Q16.ExampleServer, :start_link, 0)
    assert {:ok, pid} = Proofs.S04Q16.ExampleServer.start_link()
    GenServer.stop(pid)
  end
end
