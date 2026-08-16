defmodule Proofs.S03Q12EtsMatchTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 3 of 12 — ETS
  Question    : 12 of 60 (7 of 7 in section)
  External ID : V7DHOwMSXaY

  Question text:
    Table :some_table, type `bag`, containing:
      {:products, "Tesla", "Audi",  "Toyota", "Ford"}
      {:products, "Tesla", "Honda", "Toyota", "Ford"}
      {:products, "BMW",   "Audi",  "Subaru", "Volvo"}

    "What is the result of the following call?"
      :ets.match(:some_table, {:products, :'$2', :_, :'$1', :_})

    Response type: Multiple correct
    A. It returns a list of three tuples with all elements.
    B. It returns a list of three lists. Each of the lists contains the second,
       then the fourth element of the tuple.        <- candidate selected, marked WRONG

  Candidate : B  (marked Incorrect, 0/1)
  Reality   : NEITHER option is correct. VERDICT = FALSE (question is broken).

  Measured on 1.19.1 / OTP 28:

      [["Toyota", "Tesla"], ["Toyota", "Tesla"], ["Subaru", "BMW"]]

  `:ets.match/2` returns the bound variables ordered by VARIABLE NUMBER
  ($1, $2, $3...), not by their position in the tuple. The pattern binds
  position 2 to :'$2' and position 4 to :'$1', so each inner list is
  [$1, $2] = [fourth element, SECOND element].

  Option B has the right shape — three lists — but states the order exactly
  backwards: it says "the second, then the fourth". The truth is the fourth,
  then the second. That reversal is the entire point of numbering the variables
  out of order in the pattern, so it cannot be dismissed as a wording quibble.

  Option A is wrong twice over: the results are lists, not tuples, and they hold
  only the bound variables, not "all elements".
  """

  setup do
    t = :ets.new(:proof_q12, [:bag])
    :ets.insert(t, {:products, "Tesla", "Audi", "Toyota", "Ford"})
    :ets.insert(t, {:products, "Tesla", "Honda", "Toyota", "Ford"})
    :ets.insert(t, {:products, "BMW", "Audi", "Subaru", "Volvo"})
    {:ok, table: t}
  end

  test "the actual result — order is [$1, $2] = [fourth, second]", %{table: t} do
    result = :ets.match(t, {:products, :"$2", :_, :"$1", :_})

    assert Enum.sort(result) ==
             Enum.sort([["Toyota", "Tesla"], ["Toyota", "Tesla"], ["Subaru", "BMW"]])

    # Three results (the bag keeps both distinct "Tesla" rows).
    assert length(result) == 3
  end

  test "A is FALSE — the results are lists, and not 'all elements'", %{table: t} do
    result = :ets.match(t, {:products, :"$2", :_, :"$1", :_})

    assert Enum.all?(result, &is_list/1)
    refute Enum.any?(result, &is_tuple/1)
    # Each holds 2 bound variables, not the tuple's 5 elements.
    assert Enum.all?(result, &(length(&1) == 2))
  end

  test "B is FALSE — the order is reversed from what B claims", %{table: t} do
    [first | _] = :ets.match(t, {:products, :"$2", :_, :"$1", :_})

    second_element = "Tesla"
    fourth_element = "Toyota"

    # What B claims: [second, fourth]
    refute first == [second_element, fourth_element]
    # What actually happens: [fourth, second] — ordered by $1 then $2
    assert first == [fourth_element, second_element]
  end

  test "CONTROL: renumbering the variables flips the output order", %{table: t} do
    # Same positions, but $1 now marks position 2 -> the order inverts.
    [first | _] = :ets.match(t, {:products, :"$1", :_, :"$2", :_})
    assert first == ["Tesla", "Toyota"]
  end
end
