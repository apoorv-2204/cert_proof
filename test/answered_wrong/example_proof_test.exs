defmodule Proofs.ExampleProofTest do
  use ExUnit.Case, async: true

  @moduledoc """
  PROOF FORMAT EXAMPLE

  Question  : "In Elixir, a String is a list of characters."
  Exam says : TRUE
  Reality   : FALSE — a String is a UTF-8 encoded binary.
  """

  test "a String is a binary, NOT a list" do
    s = "hi"

    assert is_binary(s)
    refute is_list(s)

    # the byte-level truth
    assert s == <<104, 105>>
    assert byte_size(s) == 2

    # a charlist is the list-of-codepoints thing; it is a DIFFERENT type
    cl = ~c"hi"
    assert is_list(cl)
    assert cl == [104, 105]
    refute s == cl
  end

  test "length/1 does not even accept a String" do
    # Called through apply/3 so the compiler does not reject it statically —
    # that it CAN be rejected statically is itself part of the proof.
    assert_raise ArgumentError, fn -> apply(Kernel, :length, ["hi"]) end
    assert String.length("hi") == 2
  end
end
