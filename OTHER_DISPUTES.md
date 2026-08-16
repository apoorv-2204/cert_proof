# Other Disputed Questions — candidate's answer was also wrong

These are the questions where the exam's key looks wrong **but the candidate's
answer was not correct either**, so there are no marks to reclaim. They are kept
because most are still genuine defects: the ask for these is to **void the
question**, not to award the mark.

Proofs live in [test/answered_wrong/](test/answered_wrong/) and run as part of
the normal `mix test`.

The marks actually recoverable are in [README.md](README.md).

**Verified on Elixir 1.19.1 / Erlang OTP 28 (erts-16.1.1), Linux.**

---

## Summary

| Q | Section | Topic | Measured truth | Verdict |
|---|---|---|---|---|
| 7 | 3 — ETS | What stores ETS content | a **tuple** | key is wrong (`%ETS.Record{}` is fictional) |
| 12 | 3 — ETS | `:ets.match` result | `[["Toyota","Tesla"], …]` | no correct option |
| 14 | 4 — GenServer | `terminate/2` on abnormal supervisor death | it runs; `trap_exit` decides | no correct option |
| 16 | 4 — GenServer | `start_link` with no `init/1` | `{:ok, pid}`, no crash | no correct option |
| 17 | 4 — GenServer | `GenServer.start_link/3` return | `{:ok, pid}` | no correct option |
| 36 | 7 — Mix | Purpose of `deps/` | source code — A is true | key wrongly excludes A |
| 41 | 9 — Registry | Registry instance exits | neither — processes **die** | no correct option |
| 39 | 8 — Protocols | Normal + callback functions | true | **exam was right; candidate wrong** |

---

## Write-ups

### Q7 and Q12 — ETS (Section 3)

**Q7** (`fQI0tBZEGVQ`): the answer is **a tuple**. Inserting a list, binary,
integer, map or atom all raise `ArgumentError`; what may be any term is each
*element inside* the tuple. Option A garbles that; option B is fictional —
`ETS.Record` does not exist in Elixir or OTP. Neither option is correct, but a key
selecting a non-existent struct cannot stand.

**Q12** (`V7DHOwMSXaY`): the call returns

```elixir
[["Toyota", "Tesla"], ["Toyota", "Tesla"], ["Subaru", "BMW"]]
```

`:ets.match/2` orders results by **variable number** (`$1`, `$2`, …), not tuple
position. The pattern binds position 2 to `:"$2"` and position 4 to `:"$1"`, so
each list is `[fourth, second]`. Option B has the right shape but states the order
**exactly backwards**; option A is wrong twice (lists, not tuples; bound variables
only, not all elements). Numbering the variables out of order is the entire point
of the question, so the reversal is not a wording quibble.

### Q14 — `terminate/2` does run (Section 4, `bFxIfcxBIY`)

Three separate defects:

1. **The question's code does not compile.** The flag is `:trap_exit`, not
   `:trap_exits`; `Process.flag(:trap_exits, true)` raises `ArgumentError`.
   Taken literally the premise is impossible.
2. **A is false.** With exits trapped, a killed supervisor leaves the child
   holding `{:EXIT, sup, :killed}`, and `gen_server` responds to a parent exit by
   running `terminate/2`. The crash report shows it: `Last message: {:EXIT, #PID<…>, :killed}`.
3. **B is false.** Strategy is irrelevant:

   | strategy | `trap_exit: true` | `trap_exit: false` |
   |---|---|---|
   | `:one_for_one` | ran (`:killed`) | did not run |
   | `:one_for_all` | ran (`:killed`) | did not run |
   | `:rest_for_one` | ran (`:killed`) | did not run |

The supervisor's other abnormal death — exceeding restart intensity — also runs
`terminate/2`, with reason `:shutdown`.

### Q16 and Q17 — GenServer return values (Section 4)

**Q16** (`ByEUMyrqgk`): returns `{:ok, pid}` and the server **does not crash** —
`use GenServer` injects a default `init/1` returning `{:ok, init_arg}`, so state is
`nil` and the process stays alive. A confuses the state for the return value; B is
right about `{:ok, pid}` but wrong about crashing; C misreads a *warning*
("We will inject a default implementation for now") as an error. None correct.

**Q17** (`jKRHKxfxyP`): `GenServer.start_link/3` returns `{:ok, pid}`. None of the
five options says that. Option A describes what `init/1` returns, not
`start_link/3`; option B describes `spawn/1`. None correct.

---

### Q36 — `deps/` holds source code (Section 7, `5WRpqRfvPX`)

Both selected options are marked with a red X and neither carries the grey
"correct but unselected" tick that this UI shows elsewhere (see Q37 option A), so
the key excludes A. Yet after `mix deps.get`:

```
deps/jason/lib/encode.ex, decoder.ex, codegen.ex, …   <- Elixir source
deps/jason/mix.exs                                    <- the dep's own project file
```

Zero `.html` files under `deps/`. Generated docs go to `doc/`, which only exists
after `mix docs`. **A is true.** (The candidate's own answer was still wrong,
because they also selected B. The dispute is about the key, not the score.)

### Q41 — Registered processes do not survive (Section 9, `z6CzVBScRLQ`)

Both options begin "The registered processes continue to work." They do not.
`Registry.register/3` **links** the caller to the registry partition — from
Elixir's own `lib/elixir/lib/registry.ex`:

```elixir
Process.link(pid_server)
```

| Registry exit mode | worker traps exits | worker alive after? |
|---|---|---|
| `Process.exit(reg, :kill)` | false | **no** |
| `Process.exit(reg, :kill)` | true | yes |
| `Supervisor.stop(reg)` | false | **no** |
| `Supervisor.stop(reg)` | true | yes |

It dies under an *orderly* stop too, so this is not a `:kill` artifact. On the
half where the options differ, A is right (entries are lost; the ETS tables are
destroyed, `:ets.lookup` then raises) and B is wrong. **A is strictly closer to
the truth than B, and the exam marked A wrong.**

### Q39 — Normal and callback functions in protocols (Section 8, `aK8gykyYCR`)

The exam says **true**, the candidate said false, and **the exam is right.**
Recorded here because conceding it makes the rest of the disputes stronger.

Every protocol module already carries ordinary functions — `impl_for/1`,
`impl_for!/1`, `__protocol__/1` — emitted via `Kernel.def` by Elixir's own
`protocol.ex`. You can add your own the same way. Callbacks are there too: bare
`def/1` signatures become the behaviour's callbacks, and an explicit `@callback`
registers as well (with a discouraging warning).

The trap is that the *idiomatic* spelling `def foo(x), do: …` fails with
"undefined function def/2", because `defprotocol` imports `Protocol.def/1` instead
of `Kernel.def/2`. Only the spelling is blocked, not the capability.

---

---

## Note on Q39

Q39 is the one the exam got right. Concede it up front when filing — it costs
nothing and makes the other claims credible.

---

<!-- BEGIN QUESTIONS (generated by sync_readme_questions.py) -->

## Questions verbatim

Copied from the proof files' moduledocs — the wording there is the source
of truth. Regenerate with `python3 sync_readme_questions.py`.

### Q7 — Section 3 of 12 — ETS

`External ID: fQI0tBZEGVQ` · Question 7 of 60 (2 of 7 in section) · [proof](test/answered_wrong/s03_q07_ets_data_structure_test.exs)

```text
"What data structure is used to store content in ETS table?"

Response type: Multiple correct
A. Any Erlang or Elixir term.        <- candidate selected, marked WRONG
B. %ETS.Record{...} struct.
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A  (marked Incorrect, 0/1)  
**Reality:** the true answer is "a TUPLE". VERDICT = FALSE (exam wrong).

### Q12 — Section 3 of 12 — ETS

`External ID: V7DHOwMSXaY` · Question 12 of 60 (7 of 7 in section) · [proof](test/answered_wrong/s03_q12_ets_match_test.exs)

```text
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
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** B  (marked Incorrect, 0/1)  
**Reality:** NEITHER option is correct. VERDICT = FALSE (question is broken).

### Q14 — Section 4 of 12 — Gen Server

`External ID: bFxIfcxBIY` · Question 14 of 60 (2 of 11 in section) · [proof](test/answered_wrong/s04_q14_genserver_abnormal_terminate_test.exs)

```text
"Given a Supervisor. The child process is a GenServer which has a
 terminate/2 callback function that performs some cleanup. GenServer is
 configured to trap exits with `Process.flag(:trap_exits, true)` in its
 init/1 callback. If the supervisor terminated abnormally, will the
 GenServer's terminate/2 be invoked?"

Response type: Multiple correct
A. No. If the Supervisor is terminated abnormally, all of the child
   processes are terminated immediately.                    <- candidate answered
B. Depends on the strategy of the Supervisor.
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A  (marked Incorrect, 0/1)  
**Reality:** NEITHER A NOR B IS CORRECT. VERDICT = FALSE (question is broken).

### Q16 — Section 4 of 12 — Gen Server

`External ID: ByEUMyrqgk` · Question 16 of 60 (4 of 11 in section) · [proof](test/answered_wrong/s04_q16_genserver_default_init_test.exs)

```text
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
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** B  (marked Incorrect, 0/1)  
**Reality:** it returns {:ok, pid} and the server does NOT crash.

### Q17 — Section 4 of 12 — Gen Server

`External ID: jKRHKxfxyP` · Question 17 of 60 (5 of 11 in section) · [proof](test/answered_wrong/s04_q17_genserver_start_link_return_test.exs)

```text
"Assuming that the gen_server is successfully created and initialized using
 GenServer.start_link/3 function, what is the result of this function?"

Response type: Multiple correct
A. {:ok, state}, where state is the second argument of start_link/3.
B. pid only.        <- candidate answered
C. nil
D. true
E. {:ok, true}
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** B  (marked Incorrect, 0/1)  
**Reality:** it returns {:ok, pid}. VERDICT = FALSE (no option is correct).

### Q36 — Section 7 of 12 — Mix

`External ID: 5WRpqRfvPX` · Question 36 of 60 (2 of 2 in section) · [proof](test/answered_wrong/s07_q36_deps_directory_test.exs)

```text
"What is the purpose of the `deps` directory in a Mix project?"

Response type: Multiple correct
A. It contains the source code for the project's dependencies.  <- candidate selected, marked WRONG
B. It contains documentation for the project's dependencies.    <- candidate selected, marked WRONG
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A + B  (marked Incorrect, 0/1)  
**Reality:** A is TRUE, B is FALSE. VERDICT = FALSE (the exam is wrong).

### Q39 — Section 8 of 12 — Protocols

`External ID: aK8gykyYCR` · Question 39 of 60 (3 of 4 in section) · [proof](test/answered_wrong/s08_q39_protocols_function_definitions_test.exs)

```text
"You can define both normal and callback functions in Protocols in Elixir."

Response type: Single correct
A. true    <- exam marked correct (grey tick on the results screen)
B. false   <- candidate answered (marked Incorrect, 0/1)
```

**Exam key:** A  
**Candidate:** ?  
**Reality:** ?

### Q41 — Section 9 of 12 — Registry

`External ID: z6CzVBScRLQ` · Question 41 of 60 (1 of 4 in section) · [proof](test/answered_wrong/s09_q41_registry_exit_test.exs)

```text
"What does happen to the registered processes if a Registry instance exits?"

Response type: Multiple correct
A. The registered processes continue to work, but all the entries in the
   registry will be lost.                                  <- candidate answered
B. The registered processes continue to work. We can access registered items
   directly from ETS tables even after the registry has exited.
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A  (marked Incorrect, 0/1)  
**Reality:** NEITHER option is correct. VERDICT = FALSE (question is broken).

<!-- END QUESTIONS -->
