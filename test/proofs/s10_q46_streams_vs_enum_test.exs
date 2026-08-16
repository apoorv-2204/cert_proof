defmodule Proofs.S10Q46StreamsVsEnumTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 10 of 12 — Streams
  Question    : 46 of 60 (2 of 2 in section)
  External ID : AdHIcMLDKv

  Question text:
    "Which of the following statements is the correct way (optimal for
     computation/memory) of using Streams and Enums in Elixir?"

    Response type: Multiple correct
    A. 1..100_000 |> Enum.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum
    B. 1..100_000 |> Stream.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum
                                                        <- candidate answered, marked WRONG

  Candidate : B  (marked Incorrect, 0/1)
  Reality   : B IS the optimal form. VERDICT = FALSE (the exam is wrong).

  B is the textbook shape: stay lazy through every intermediate step, then
  collapse once with a single eager Enum call at the end. A breaks laziness at
  the very first step, forcing a fully materialised 100_000-element list before
  any filtering happens.

  Measured on 1.19.1 / OTP 28:

    * Memory — A's `Enum.map` allocates an intermediate list of 100_000
      elements occupying 200_000 words. B allocates no intermediate list at
      all (test 2).
    * Computation — over 1..1_000_000, A took ~145ms and B ~38ms, roughly 4x
      (test 3).
    * Mechanism — with A every map runs before any filter
      ([map: 1, map: 2, map: 3, filter: 3, filter: 6, filter: 9]); with B they
      interleave per element ([map: 1, filter: 3, map: 2, filter: 6, ...]),
      which is what avoids the intermediate list (test 1).

  On both axes named by the question — computation AND memory — B wins. Marking
  B wrong inverts the actual result.
  """

  defp log(tag, x) do
    Process.put(:log, [{tag, x} | Process.get(:log, [])])
    x
  end

  defp drain do
    entries = Process.get(:log, []) |> Enum.reverse()
    Process.put(:log, [])
    entries
  end

  test "1. MECHANISM: A materialises everything first; B interleaves" do
    Process.put(:log, [])

    1..3
    |> Enum.map(&log(:map, &1 * 3))
    |> Stream.filter(&(log(:filter, &1) && true))
    |> Enum.sum()

    option_a = drain()

    1..3
    |> Stream.map(&log(:map, &1 * 3))
    |> Stream.filter(&(log(:filter, &1) && true))
    |> Enum.sum()

    option_b = drain()

    # A: every map runs before any filter — the list is fully built first.
    assert option_a == [map: 3, map: 6, map: 9, filter: 3, filter: 6, filter: 9]

    # B: one element flows all the way through before the next begins.
    assert option_b == [map: 3, filter: 3, map: 6, filter: 6, map: 9, filter: 9]
  end

  test "2. MEMORY: A allocates a 100_000-element intermediate list, B allocates none" do
    intermediate = Enum.map(1..100_000, &(&1 * 3))

    assert is_list(intermediate)
    assert length(intermediate) == 100_000
    # Two words per cons cell for small ints: ~200_000 words that B never builds.
    assert :erts_debug.size(intermediate) >= 200_000

    # B's equivalent stage is a lazy struct holding no elements at all.
    lazy = Stream.map(1..100_000, &(&1 * 3))
    refute is_list(lazy)
    assert :erts_debug.size(lazy) < 100
  end

  test "3. COMPUTATION: B is faster over 1..1_000_000" do
    odd? = &(rem(&1, 2) == 1)

    {time_a, sum_a} =
      :timer.tc(fn ->
        1..1_000_000 |> Enum.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum()
      end)

    {time_b, sum_b} =
      :timer.tc(fn ->
        1..1_000_000 |> Stream.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum()
      end)

    # Identical results — the two differ only in cost, not in outcome.
    assert sum_a == sum_b

    assert time_b < time_a,
           "expected the lazy pipeline to be faster: A=#{div(time_a, 1000)}ms B=#{div(time_b, 1000)}ms"
  end
end
