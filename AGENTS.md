# AGENTS.md

## What this project is

A harness for **disputing Elixir certification exam questions**. The user sat a
certification exam, and believes several questions were marked with answers that
are factually wrong. This repo builds *executable proof* — runnable ExUnit tests
that demonstrate what Elixir actually does — so the claims can be challenged with
evidence rather than assertion.

The deliverable is a report that could be sent to a certification body: one proof
per disputed question, with version-pinned output.

## Environment

Do **not** use Docker. Everything runs locally against the installed toolchain.

| Thing | Value |
|---|---|
| Elixir | 1.19.1 (via asdf) |
| Erlang/OTP | 28 (erts-16.1.1) |
| `.tool-versions` | `elixir 1.19.1-otp-28`, `erlang 28.1.1` (from `~/.tool-versions`) |
| Platform | Linux, zsh |

asdf is at `/home/apoorv_2204/bin/asdf`; `elixir`/`mix`/`erl` resolve through
`~/.asdf/shims/`. No extra setup needed — just run `mix`.

## Layout

```
cert_proof/                      <- the git repo (github.com/apoorv-2204/cert_proof)
├── AGENTS.md                    <- conventions (this file)
├── README.md                    <- FINDINGS: the 5 questions the candidate got right
├── OTHER_DISPUTES.md            <- questions the candidate also got wrong
├── evidence/                    <- results-screen screenshots, filed by outcome
├── sync_readme_questions.py     <- regenerates README's "Questions verbatim" appendix
├── mix.exs
├── lib/
└── test/
    ├── test_helper.exs
    ├── proofs/                  <- candidate answered correctly, key was wrong
    └── answered_wrong/          <- candidate's answer was also wrong
        ├── s02_q05_node_spawn_link_dead_node_test.exs
        ├── s03_q07_ets_data_structure_test.exs
        ├── s03_q12_ets_match_test.exs
        ├── s04_q14_genserver_abnormal_terminate_test.exs
        ├── s04_q16_genserver_default_init_test.exs
        ├── s04_q17_genserver_start_link_return_test.exs
        ├── s07_q36_deps_directory_test.exs
        ├── s08_q37_protocols_polymorphism_test.exs
        ├── s09_q41_registry_exit_test.exs
        ├── s10_q46_streams_vs_enum_test.exs
        ├── s11_q48_supervise_os_processes_test.exs
        └── s11_q54_supervisor_init_failure_test.exs
```

## Running

```sh
cd cert_proof
mix test                                    # everything
mix test test/proofs/example_proof_test.exs # one proof
```

Baseline is green. If something fails that isn't *meant* to fail, that's a real
problem — investigate, don't paper over it.

## File naming and labelling

The exam numbers each question three ways. Capture all three — the global
number is the unique one, the section number is how the exam groups topics.

> `Question 8 of 10 | Supervisors` · `Section 11 of 12` · `Question 54 of 60`

### File name

```
test/proofs/s<SECTION>_q<GLOBAL_QUESTION>_<topic>_test.exs
```

e.g. `s11_q54_supervisor_init_failure_test.exs` — section 11, question 54 of 60,
topic "supervisor init failure". Topic is short `snake_case`, describing the
*claim under test*, not the section name. Files sort in exam order, which is what
you want when assembling the report.

### Module names

```elixir
defmodule Proofs.S11Q54SupervisorInitFailureTest   # the test module
defmodule Proofs.S11Q54.AlwaysFailsInit            # helper/child modules
```

Helper modules (GenServers, supervisors, structs the proof needs) go under the
`Proofs.S<S>Q<Q>.` namespace so two proofs can never collide on a name.

### Required moduledoc header

Every proof file opens with this block, filled in from the results screen. The
IDs matter — a dispute is only actionable if the certification body can look the
question up.

```elixir
@moduledoc """
Exam      : Elixir Online Advanced Exam 2025
Section   : 11 of 12 — Supervisors
Question  : 54 of 60 (8 of 10 in section)
Question ID / Source ID : uMmsvUudbZp
External ID             : DYoKKwfhjM
Response ID             : 2E8HmG--f_0

Question text:
  "<verbatim question text>"

  A. <option text>                      <- candidate answered
  B. <option text>                      <- exam marked correct

Exam says : B
Candidate : A  (marked Incorrect, 0/1)
Reality   : <verdict + one-line why>
"""
```

Copy the question text **verbatim**, including its original grammar. Wording is
often the whole basis of the dispute, so paraphrasing destroys the evidence.

### Test naming

Number the tests in argument order so the file reads as a case:

```elixir
test "1. init/1 failing at start-up terminates the Supervisor — it never restarts the child"
test "2. CONTROL: a healthy child does start, proving the setup is valid"
test "3. Even the generous reading of B ends with the Supervisor terminated"
```

Always include a **CONTROL** test that shows the happy path working. Without it,
a reviewer can dismiss the whole proof as a broken test setup.


## Proof format

One file per disputed question, in `test/proofs/`. Every file opens
with a `@moduledoc` stating four things, then proves the claim with assertions:

```elixir
defmodule Proofs.ExampleProofTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Question  : "In Elixir, a String is a list of characters."
  Exam says : TRUE
  Reality   : FALSE — a String is a UTF-8 encoded binary.
  """

  test "a String is a binary, NOT a list" do
    s = "hi"
    assert is_binary(s)
    refute is_list(s)
    assert s == <<104, 105>>

    cl = ~c"hi"          # a charlist IS a list — different type
    assert is_list(cl)
    refute s == cl
  end
end
```

Rules for writing proofs:

- **Prove positively and negatively.** `assert is_binary(s)` *and*
  `refute is_list(s)`. Showing what a thing is not is half the argument.
- **Show the underlying representation** where it settles the matter
  (`<<104, 105>>`, `byte_size/1`, `:erlang.term_to_binary/1`).
- **Contrast with the adjacent thing** the exam probably confused it with
  (String vs charlist, `length/1` vs `String.length/1`, link vs monitor).
- Keep tests `async: true` unless the proof needs global state or traps exits.
- Compiler warnings can themselves be evidence — e.g. Elixir statically rejects
  `length("hi")`. Note these in the moduledoc when they strengthen the case.

## Verdict categories — be honest

Each disputed question gets exactly one verdict. **Do not force everything into
"exam is wrong."** A dispute is far stronger when it isn't over-claimed.

- `FALSE` — the exam's marked answer is factually incorrect. Prove it.
- `VERSION-DEPENDENT` — was true in some Elixir/OTP version, not in 1.19/28 (or
  vice versa). State which versions, and which the exam should have specified.
- `AMBIGUOUS` — wording admits more than one defensible reading. Show both
  readings running, and argue the question is unanswerable as written.
- `CORRECT` — the exam was right and the misunderstanding is the user's. **Say
  so plainly.** Explain the real semantics. Never manufacture a proof to
  validate a wrong dispute.

## Workflow when the user supplies questions

For each question the user needs to give: question text, options (if MCQ),
**what the exam marked correct** (this is the claim under test), and their own
answer/reasoning.

Then:

1. One new file per question in `test/proofs/`, named for the topic.
2. Determine the verdict *before* writing assertions — research the actual
   semantics first, don't reverse-engineer a conclusion.
3. Write the proof, run it, confirm green.
4. Add it to the report.

## Notes

- OTP-behavior questions (supervisors, crashes, restarts, timeouts, exit
  signals) need **real running processes**, not pure assertions. Spawn real
  supervised children and observe. This needs no containers.
- Pin evidence to versions. Any report should quote `elixir --version` output,
  since "what Elixir does" is only meaningful against a stated version.
- Questions about the *standard library* can often be settled by citing the
  actual source in `~/.asdf/installs/elixir/1.19.1-otp-28/`.

## Findings live in README.md

`README.md` is the deliverable: the verdict table, the per-question write-ups, and
the filing notes. **Update it whenever you add or change a proof** — it is the
thing the certification body would actually read. Do not keep a second copy of the
findings here; this file is for conventions only.

## Recording a verdict honestly

Q41 is the worked example. The first exploration accidentally tested an
*unregistered* process and concluded that registered processes survive a
Registry exit. Writing the real test exposed that `Registry.register/3` calls
`Process.link/1`, which reversed the finding entirely — and turned out to sink
both offered options.

The rule that came out of it: run the code before writing the verdict, and when
the measurement contradicts an earlier conclusion, change the conclusion. A
verdict that was reverse-engineered to support a dispute is worse than useless,
because one wrong claim discredits the rest.

