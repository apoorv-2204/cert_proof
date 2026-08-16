defprotocol Proofs.S08Q37Proto.Describe do
  @spec describe(t) :: String.t()
  def describe(x)
end

defimpl Proofs.S08Q37Proto.Describe, for: Integer do
  def describe(i), do: "int #{i}"
end

defimpl Proofs.S08Q37Proto.Describe, for: BitString do
  def describe(s), do: "string #{s}"
end

defmodule Proofs.S08Q37ProtocolsPolymorphismTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias Proofs.S08Q37Proto.Describe

  @moduledoc """
  Exam      : Elixir Online Advanced Exam 2025
  Section     : 8 of 12 — Protocols
  Question    : 37 of 60 (1 of 4 in section)
  External ID : yisnw2In10

  Question text:
    "Regarding Protocols in Elixir, which of the following statements are true?
     Pick all that apply."

    Response type: Multiple correct
    A. Protocols offer compile-time polymorphism
    B. Protocols are impure interfaces
    C. Protocols are pure interfaces          <- candidate selected
    D. Protocols offer runtime polymorphism   <- candidate selected
    E. Protocols are not interfaces

  Exam key  : A + C   (A shows a grey "correct, unselected" tick; C shows a
              green "correct, selected" tick; D shows a red X)
  Candidate : C + D  (marked Incorrect, 0/1)
  Reality   : C + D is the correct set. VERDICT = FALSE (exam wrong).

  The exam and the candidate agree on C. The dispute is the exact swap of A and
  D: the key says protocols are COMPILE-TIME polymorphic and not runtime
  polymorphic. That is backwards, and it is the single most testable claim in
  this whole question — see tests 1 and 2.

    D true  — dispatch is resolved from the VALUE'S TYPE AT RUNTIME (test 1).
    A false — nothing is resolved at compile time; a call to a type with no
              implementation compiles cleanly and only blows up when run (test 2).
    E false — a protocol IS an interface; Elixir compiles it to a behaviour, and
              `behaviour_info(:callbacks)` lists its functions (test 3).
    B false /
    C true  — a protocol admits no implementations whatsoever: a function with a
              body is a hard compile error (test 4). Declaration only = pure
              interface.

  Anticipated rebuttals:

  * "Consolidation makes it compile-time." Protocol consolidation only
    pre-computes the dispatch table for speed; which implementation runs still
    depends on the runtime type of the value. Test 2 shows the failure surfacing
    at runtime, and test 1 dispatches on values the compiler cannot know.
  * "@fallback_to_any / defimpl Any give it a default, so it is impure." That
    default lives in a SEPARATE `defimpl` module, never in the protocol
    declaration. The declaration stays implementation-free (test 4).
  """

  test "1. D is TRUE — the implementation is chosen from the runtime value's type" do
    # Shuffled so no compile-time constant folding can be claimed.
    for v <- Enum.shuffle([1, "hi"]) do
      assert Describe.describe(v) == expected(v)
    end

    assert Describe.impl_for(1) == Proofs.S08Q37Proto.Describe.Integer
    assert Describe.impl_for("hi") == Proofs.S08Q37Proto.Describe.BitString

    # An unimplemented type resolves to nil — a lookup, performed at runtime.
    assert Describe.impl_for(:atom) == nil
  end

  defp expected(v) when is_integer(v), do: "int #{v}"
  defp expected(v) when is_binary(v), do: "string #{v}"

  test "2. A is FALSE — a call with no implementation COMPILES, then fails at runtime" do
    src = """
    defmodule Proofs.S08Q37Proto.CallsMissingImpl do
      def go, do: Proofs.S08Q37Proto.Describe.describe(:atom_has_no_impl)
    end
    """

    # Compiles without complaint: the compiler does not resolve the target.
    capture_io(:stderr, fn -> assert [_ | _] = Code.compile_string(src) end)

    # The error only exists once the value actually flows through, at runtime.
    assert_raise Protocol.UndefinedError, fn ->
      Proofs.S08Q37Proto.CallsMissingImpl.go()
    end
  end

  test "3. E is FALSE — a protocol is literally a behaviour, i.e. an interface" do
    assert function_exported?(Describe, :behaviour_info, 1)
    assert Describe.behaviour_info(:callbacks) == [describe: 1]
  end

  test "4. C is TRUE / B is FALSE — a protocol can hold no implementation at all" do
    src = """
    defprotocol Proofs.S08Q37Proto.Impure do
      def declared(x)
      def implemented(x), do: :this_is_a_body
    end
    """

    output =
      capture_io(:stderr, fn ->
        assert_raise CompileError, fn -> Code.compile_string(src) end
      end)

    assert output =~ "undefined function def/2"
  end
end
