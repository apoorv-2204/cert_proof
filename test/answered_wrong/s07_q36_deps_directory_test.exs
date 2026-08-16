defmodule Proofs.S07Q36DepsDirectoryTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Exam      : Elixir Online Advanced Exam 2025
  Section     : 7 of 12 — Mix
  Question    : 36 of 60 (2 of 2 in section)
  External ID : 5WRpqRfvPX

  Question text:
    "What is the purpose of the `deps` directory in a Mix project?"

    Response type: Multiple correct
    A. It contains the source code for the project's dependencies.  <- candidate selected, marked WRONG
    B. It contains documentation for the project's dependencies.    <- candidate selected, marked WRONG

  Candidate : A + B  (marked Incorrect, 0/1)
  Reality   : A is TRUE, B is FALSE. VERDICT = FALSE (the exam is wrong).

  The results screen marks BOTH selected options with a red X and shows no grey
  "correct but unselected" tick on either. On this exam UI a correct-but-
  unselected option renders as a grey tick (see Q37, where option A does exactly
  that). Its absence here means the key excludes A — and A is demonstrably true,
  which is the error.

  The candidate's own answer was also wrong, because including B made the set
  wrong. The dispute is not "my answer was right"; it is "A is true and the key
  says otherwise".

  Reproduce: `mix deps.get && mix test`
  """

  test "deps/ holds dependency SOURCE CODE — option A is true" do
    deps_path = Mix.Project.deps_path()
    assert Path.basename(deps_path) == "deps"

    jason = Path.join(deps_path, "jason")
    assert File.dir?(jason), "run `mix deps.get` first"

    # Actual Elixir source modules, not artifacts and not docs.
    sources = Path.wildcard(Path.join(jason, "lib/**/*.ex"))
    assert length(sources) > 0
    assert Enum.any?(sources, &(Path.basename(&1) == "encode.ex"))

    # It is a full source checkout: the dependency's own mix.exs ships with it.
    assert File.exists?(Path.join(jason, "mix.exs"))

    # And the source is readable Elixir, not compiled output.
    assert File.read!(Path.join(jason, "lib/encode.ex")) =~ "defmodule"
  end

  test "deps/ holds NO documentation — option B is false" do
    deps_path = Mix.Project.deps_path()

    html = Path.wildcard(Path.join(deps_path, "**/*.html"))
    assert html == [], "expected no generated documentation in deps/, got: #{inspect(html)}"

    # Generated docs are a separate concern entirely: ExDoc writes to doc/,
    # which is not deps/ and does not exist unless you run `mix docs`.
    assert Path.basename(deps_path) != "doc"
  end
end
