defmodule Proofs.S04Q17.Server do
  use GenServer
  def init(arg), do: {:ok, arg}
end

defmodule Proofs.S04Q17GenserverStartLinkReturnTest do
  use ExUnit.Case, async: true

  alias Proofs.S04Q17.Server

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 4 of 12 — Gen Server
  Question    : 17 of 60 (5 of 11 in section)
  External ID : jKRHKxfxyP

  Question text:
    "Assuming that the gen_server is successfully created and initialized using
     GenServer.start_link/3 function, what is the result of this function?"

    Response type: Multiple correct
    A. {:ok, state}, where state is the second argument of start_link/3.
    B. pid only.        <- candidate answered
    C. nil
    D. true
    E. {:ok, true}

  Candidate : B  (marked Incorrect, 0/1)
  Reality   : it returns {:ok, pid}. VERDICT = FALSE (no option is correct).

  `GenServer.start_link/3` returns `{:ok, pid}` on success. Not one of the five
  options says that:

    * A — {:ok, state} is what the init/1 CALLBACK returns, not what
      start_link/3 returns. Test 2 shows the two side by side: init/1 receives
      :my_state and returns {:ok, :my_state}, while start_link/3 returns
      {:ok, #PID<...>}. Conflating them is the error the option encodes.
    * B — a bare pid is what `spawn/1` returns, not start_link/3 (test 3).
    * C, D, E — not returned under any circumstances (test 1).

  The candidate's B is wrong, but so is every other choice, so the question is
  unanswerable as written.
  """

  test "1. GenServer.start_link/3 returns {:ok, pid} — and none of the offered options" do
    result = GenServer.start_link(Server, :my_state, [])

    assert {:ok, pid} = result
    assert is_pid(pid)

    # Explicitly rule out each offered answer.
    refute result == {:ok, :my_state}
    refute is_pid(result)
    refute result == nil
    refute result == true
    refute result == {:ok, true}

    GenServer.stop(pid)
  end

  test "2. A confuses start_link/3's return with init/1's return" do
    # What init/1 returns:
    assert Server.init(:my_state) == {:ok, :my_state}

    # What start_link/3 returns — a pid, not the state:
    assert {:ok, pid} = GenServer.start_link(Server, :my_state, [])
    refute elem({:ok, pid}, 1) == :my_state

    # The state is reachable, but only through the process.
    assert :sys.get_state(pid) == :my_state
    GenServer.stop(pid)
  end

  test "3. B describes spawn/1, not start_link/3" do
    bare = spawn(fn -> :ok end)
    assert is_pid(bare)

    {:ok, pid} = GenServer.start_link(Server, :s, [])
    refute is_pid({:ok, pid})
    GenServer.stop(pid)
  end
end
