defmodule Proofs.S08Q39ProtocolsFunctionDefinitionsTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  @moduledoc """
  Exam        : Elixir Online Advanced Exam 2025
  Section     : 8 of 12 — Protocols
  Question    : 39 of 60 (3 of 4 in section)
  External ID : aK8gykyYCR

  Question text:
    "You can define both normal and callback functions in Protocols in Elixir."

    Response type: Single correct
    A. true    <- exam marked correct
    B. false   <- candidate answered (marked Incorrect, 0/1)

  VERDICT = CORRECT. The exam is right and the candidate's answer is wrong.
  Recording this honestly, because disputing it would undermine the real
  disputes (Q41, Q54).

  Why "true" holds:

  * Normal functions genuinely live in protocol modules. Every protocol Elixir
    builds already carries `impl_for/1`, `impl_for!/1` and `__protocol__/1` —
    ordinary functions with bodies, not callbacks (test 1). They are emitted by
    `Kernel.def` inside `defprotocol` by Elixir's own `protocol.ex`.
  * You can add your own the same way: `Kernel.def` inside `defprotocol`
    compiles and runs (test 2).
  * Callback functions are there too: bare `def/1` signatures become the
    behaviour's callbacks (test 3), and an explicit `@callback` also registers,
    albeit with a discouraging warning (test 4).

  The trap that makes "false" feel right: the idiomatic unqualified form
  `def foo(x), do: ...` fails with "undefined function def/2", because
  `defprotocol` deliberately does not import `Kernel.def/2` — it imports
  `Protocol.def/1` instead (test 5). Only the unqualified spelling is blocked,
  not the capability.
  """

  defmodule Sample do
    # Defined here so the test file has a protocol of its own to inspect.
  end

  defprotocol Greet do
    def greet(x)
  end

  defimpl Greet, for: Integer do
    def greet(i), do: "hello #{i}"
  end

  test "1. every protocol module already contains NORMAL functions" do
    # These have bodies and are callable directly — they are not callbacks.
    assert Greet.impl_for(1) == Greet.Integer
    assert Greet.impl_for(:no_impl) == nil
    assert Greet.__protocol__(:functions) == [greet: 1]

    normal = [impl_for: 1, impl_for!: 1, __protocol__: 1]
    callbacks = Greet.behaviour_info(:callbacks)

    for {name, arity} <- normal do
      assert function_exported?(Greet, name, arity), "#{name}/#{arity} should exist"
      refute {name, arity} in callbacks, "#{name}/#{arity} is a normal function, not a callback"
    end
  end

  test "2. you can define your OWN normal function inside a protocol" do
    src = """
    defprotocol Proofs.S08Q39.EdgeProto do
      def declared(x)

      Kernel.def normal_fun(x) do
        {:has_body, x}
      end
    end
    """

    capture_io(:stderr, fn -> assert [_ | _] = Code.compile_string(src) end)

    # It really is a normal function: it runs, and it is NOT a callback.
    assert Proofs.S08Q39.EdgeProto.normal_fun(:a) == {:has_body, :a}
    assert Proofs.S08Q39.EdgeProto.behaviour_info(:callbacks) == [declared: 1]
  end

  test "3. bare def/1 signatures become the protocol's CALLBACK functions" do
    assert Greet.behaviour_info(:callbacks) == [greet: 1]
    assert function_exported?(Greet, :behaviour_info, 1)
  end

  test "4. an explicit @callback also registers (with a warning)" do
    src = """
    defprotocol Proofs.S08Q39.CallbackProto do
      @callback my_cb(term()) :: term()
      def only_signature(x)
    end
    """

    output = capture_io(:stderr, fn -> Code.compile_string(src) end)
    assert output =~ "cannot define @callback my_cb/1 inside protocol"

    # Measured, not assumed: despite the warning, it IS registered.
    callbacks = Proofs.S08Q39.CallbackProto.behaviour_info(:callbacks)
    assert {:only_signature, 1} in callbacks
    assert {:my_cb, 1} in callbacks
  end

  test "5. THE TRAP: only the unqualified `def ... do` spelling is blocked" do
    src = """
    defprotocol Proofs.S08Q39.Unqualified do
      def declared(x)
      def normal_fun(x), do: :body
    end
    """

    output =
      capture_io(:stderr, fn ->
        assert_raise CompileError, fn -> Code.compile_string(src) end
      end)

    # This is an import problem, not a statement about what protocols can hold.
    assert output =~ "undefined function def/2"
  end
end
