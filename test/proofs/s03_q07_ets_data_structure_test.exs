defmodule Proofs.S03Q07EtsDataStructureTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 3 of 12 — ETS
  Question    : 7 of 60 (2 of 7 in section)
  External ID : fQI0tBZEGVQ

  Question text:
    "What data structure is used to store content in ETS table?"

    Response type: Multiple correct
    A. Any Erlang or Elixir term.        <- candidate selected, marked WRONG
    B. %ETS.Record{...} struct.

  Candidate : A  (marked Incorrect, 0/1)
  Reality   : the true answer is "a TUPLE". VERDICT = FALSE (exam wrong).

  ETS stores objects, and every object must be a tuple. Inserting a list, a
  binary, an integer or a map all raise ArgumentError (test 1). What may be any
  Erlang or Elixir term is each ELEMENT inside that tuple (test 2) — which is
  presumably what option A was reaching for, imprecisely.

  Option B is not imprecise, it is fictional: there is no `ETS.Record` module in
  Elixir or in OTP (test 3). Since A was marked wrong, the key must be B, and a
  key that selects a struct which does not exist cannot stand.

  Strictly, neither option states the correct answer ("tuple"), so this question
  has no correct choice. But B is provably false, which is the stronger point.
  """

  setup do
    {:ok, table: :ets.new(:proof_q7, [:bag])}
  end

  test "1. an ETS object MUST be a tuple — anything else raises", %{table: t} do
    assert :ets.insert(t, {:key, 1}) == true

    for bad <- [[1, 2, 3], "a string", 42, %{a: 1}, :an_atom] do
      assert_raise ArgumentError, fn -> :ets.insert(t, bad) end
    end
  end

  test "2. the tuple's ELEMENTS may be any term — what option A half-remembers", %{table: t} do
    assert :ets.insert(t, {:k, %{a: [1, 2]}, self(), "bin", make_ref(), fn -> :ok end}) == true
    assert [{:k, %{a: [1, 2]}, _pid, "bin", _ref, _fun}] = :ets.lookup(t, :k)
  end

  test "3. option B is fictional — there is no ETS.Record" do
    refute Code.ensure_loaded?(ETS.Record)
    refute function_exported?(ETS.Record, :__struct__, 0)
  end
end
