# Elixir Online Advanced Exam 2025 — Disputed Questions

Executable evidence for questions marked incorrect on the *Elixir Online Advanced
Exam 2025*. Every claim below is proved by a runnable test, not by argument.

**Verified on Elixir 1.19.1 / Erlang OTP 28 (erts-16.1.1), Linux.**

```sh
mix deps.get
mix test          # 1 doctest, 50 tests, 0 failures
```

Each question has one file in [test/proofs/](test/proofs/),
named `s<SECTION>_q<QUESTION>_<topic>_test.exs`, opening with the question text,
the exam's key, and the measured truth.

---

## Points recoverable

Five questions where **the candidate's answer was correct and the key was wrong**.
These are the ones to claim marks back on:

| Q | Section | Candidate's answer | Why it stands |
|---|---|---|---|
| 5 | 2 — Distribution | B — useless PID + warning | verbatim the Erlang doc for `spawn_link/2`; both halves observed |
| 37 | 8 — Protocols | C + D | protocols are runtime polymorphic; the key swaps A and D |
| 46 | 10 — Streams | B — fully lazy pipeline | wins on both axes the question names |
| 48 | 11 — Supervisors | A + B — "yes, limited control" | the OS process outlives the supervisor — but confirm the full option list first |
| 54 | 11 — Supervisors | A — supervisor terminated too | the restart strategy is never consulted at start-up |

Separately, **six questions are wrong in the key but the candidate's answer was
also wrong** — Q7, Q12, Q14, Q16, Q17, Q36, Q41. For those the ask is to **void
the question**, not to award the mark. And **Q39** the exam got right; concede it.

---

## Summary

| Q | Section | Topic | Exam key | Measured truth | Verdict |
|---|---|---|---|---|---|
| 5 | 2 — Distribution | `Node.spawn_link/2` to a dead node | A * | B — useless pid + warning | **Exam wrong** |
| 7 | 3 — ETS | What stores ETS content | B `%ETS.Record{}` * | a **tuple** | **Exam wrong** |
| 12 | 3 — ETS | `:ets.match` result | A * | `[["Toyota","Tesla"], …]` | **No correct option** |
| 14 | 4 — GenServer | `terminate/2` on abnormal supervisor death | B "depends on strategy" | Yes it runs; `trap_exit` decides | **No correct option** |
| 16 | 4 — GenServer | `start_link` with no `init/1` | A or C * | `{:ok, pid}`, no crash | **No correct option** |
| 17 | 4 — GenServer | `GenServer.start_link/3` return | A * | `{:ok, pid}` | **No correct option** |
| 36 | 7 — Mix | Purpose of `deps/` | excludes A | A is true | **Exam wrong** |
| 37 | 8 — Protocols | Polymorphism / interfaces | A + C | C + D | **Exam wrong** |
| 39 | 8 — Protocols | Normal + callback functions | A "true" | true | **Exam correct** |
| 41 | 9 — Registry | Registry instance exits | B * | neither — processes **die** | **No correct option** |
| 46 | 10 — Streams | Optimal Stream/Enum pipeline | A * | B | **Exam wrong** |
| 48 | 11 — Supervisors | Supervising OS processes | not A, not B * | A and B both hold | **Exam wrong** † |
| 54 | 11 — Supervisors | `init/1` raises at start-up | B | A | **Exam wrong** |

`*` = key inferred from the results screen (the selected option is marked wrong and
no other option carries a tick). Confirm against the full option list before filing.

`†` = only two options were captured; the key must be an option not visible in the
screenshot. The **behaviour** is settled either way — see [Q48](#q48--supervising-os-processes-section-11-tdffqidppe).

**Not yet assessable:** the `Node.spawn_link/2` question. See [Open items](#open-items).

---

## The strongest disputes

### Q54 — `init/1` raises at start-up (Section 11, `DYoKKwfhjM`)

Exam says the supervisor "will attempt to restart the child according to its
restart strategy." It never gets that far. During supervisor **start-up** a child
that fails to start is not restarted at all:

```
{:error, {:shutdown, {:failed_to_start_child, BoomOnInit,
  {%RuntimeError{message: "boom in init/1"}, [...]}}}}
```

`init/1` runs **exactly once** — the restart strategy is never consulted, and no
supervisor process exists afterwards. Answer A is correct.

Even under the most generous reading (child crashes *after* a good start, and the
restart's `init/1` fails), the supervisor exhausts its intensity — `init/1` called
4 times — and exits `:shutdown`. **A is correct under both readings, B under
neither.**

### Q37 — Protocols are runtime polymorphic (Section 8, `yisnw2In10`)

The key says A ("compile-time polymorphism") and C ("pure interfaces"). The
candidate said C + D. The dispute is the exact swap of A and D.

| Claim | Verdict | Evidence |
|---|---|---|
| A. compile-time polymorphism | **false** | a call on a type with no impl **compiles cleanly**, raising `Protocol.UndefinedError` only when run |
| D. runtime polymorphism | **true** | `impl_for/1` resolves from the runtime value; `impl_for(:atom) == nil` |
| C. pure interfaces | true | agreed by both |
| E. not interfaces | false | a protocol IS a behaviour: `behaviour_info(:callbacks) == [describe: 1]` |

Pre-empting the obvious rebuttals: *consolidation* only pre-computes the dispatch
table, it does not decide which impl runs; and `@fallback_to_any` puts its default
in a separate `defimpl Any` module, never in the protocol.

### Q46 — The lazy pipeline is the optimal one (Section 10, `AdHIcMLDKv`)

The question asks which form is "optimal for computation/memory", and marks the
fully-lazy pipeline **wrong**. Measured:

| | Option A (`Enum.map` first) | Option B (`Stream.map` first) |
|---|---|---|
| intermediate list | 100 000 elements, 200 000 words | none |
| time over `1..1_000_000` | ~145 ms | ~38 ms |
| call order | all maps, then all filters | interleaved per element |

B wins on **both** axes the question names.

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

### Q48 — Supervising OS processes (Section 11, `tdFFQIDPPe`)

Both selected options are marked wrong, yet both describe exactly what happens.

An OS process cannot **be** a supervisor child directly — a child's start
function must return `{:ok, pid}`, and `System.cmd/3` returns `{output, status}`,
so the supervisor refuses to start. That strict reading is what a "No" option
would rest on.

But the standard practice works fine: a BEAM process owning a `Port` to an
external executable supervises normally. And the control really is limited —
kill the supervisor and the external process **survives as an orphan**:

```
supervised OK. external OS pid = 80354
supervisor alive? false
OS process 80354 STILL alive after supervisor died? true
ps output:   80354 ?        00:00:00 sleep
```

An *orderly* `Supervisor.stop/1` does not reap it either. So A ("will not be able
to shutdown external process") and B ("limited control") are both confirmed —
this is the well-known orphaned-port-process problem.

**Before filing, get the full option list.** Only A and B were captured and both
are marked wrong, so the key is an option that was not visible. The behaviour
above holds regardless of what that option says.

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

## Where the exam was right

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

### Q5 — `Node.spawn_link/2` to a stopped node (Section 2, `FzhHRqYbAy`)

The key marks B wrong. B is right, and it is almost a verbatim quote of the
Erlang documentation for `spawn_link/2`: *"If Node does not exist, a useless pid
is returned and an exit signal with reason noconnection is sent to the calling
process."* Measured in a real `iex --sname test@localhost`:

```
iex(test@localhost)1> Node.spawn_link(:"ghost@localhost", fn -> :x end)
RETURNED: #PID<0.117.0> is_pid=true
[warning] ** Can not start :erlang::apply,[...] ([:link]) on :ghost@localhost **
** (EXIT from #PID<0.111.0>) shell process exited with reason: no connection
```

A pid is returned *and* a warning is printed — both halves of B. Option A, "it
will return an error", is false: there is no error tuple, no raise, no throw.

The trap is that the shell *does* die, because the caller is linked and takes a
`:noconnection` exit signal. That crash is the aftermath of the call, not its
return value — the question asks what the call **returns**.

---

## Open items

Nothing blocking. The `Information` accordion on each results screen has still
not been seen expanded; if it carries the exam's official rationale, it would let
each rebuttal target their stated reasoning rather than just the answer.

---

<!-- BEGIN QUESTIONS (generated by sync_readme_questions.py) -->

## Questions verbatim

Copied from the proof files' moduledocs — the wording there is the source of
truth. Regenerate with `python3 sync_readme_questions.py`.

### Q5 — Section 2 of 12 — Distribution

`External ID: FzhHRqYbAy` · Question 5 of 60 (3 of 3 in section) · [proof](test/proofs/s02_q05_node_spawn_link_dead_node_test.exs)

```text
"Given the node started with the following command: `iex --sname test@localhost`.
 What will the `Node.spawn_link/2` call return if the other node is stopped
 or does not exist?"

Response type: Multiple correct
A. It will return an error.
B. it will return a useless PID and a warning will be printed.
                                          <- candidate answered, marked WRONG
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** B  (marked Incorrect, 0/1)  
**Reality:** B is CORRECT. VERDICT = FALSE (the exam is wrong).

### Q7 — Section 3 of 12 — ETS

`External ID: fQI0tBZEGVQ` · Question 7 of 60 (2 of 7 in section) · [proof](test/proofs/s03_q07_ets_data_structure_test.exs)

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

`External ID: V7DHOwMSXaY` · Question 12 of 60 (7 of 7 in section) · [proof](test/proofs/s03_q12_ets_match_test.exs)

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

`External ID: bFxIfcxBIY` · Question 14 of 60 (2 of 11 in section) · [proof](test/proofs/s04_q14_genserver_abnormal_terminate_test.exs)

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

`External ID: ByEUMyrqgk` · Question 16 of 60 (4 of 11 in section) · [proof](test/proofs/s04_q16_genserver_default_init_test.exs)

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

`External ID: jKRHKxfxyP` · Question 17 of 60 (5 of 11 in section) · [proof](test/proofs/s04_q17_genserver_start_link_return_test.exs)

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

`External ID: 5WRpqRfvPX` · Question 36 of 60 (2 of 2 in section) · [proof](test/proofs/s07_q36_deps_directory_test.exs)

```text
"What is the purpose of the `deps` directory in a Mix project?"

Response type: Multiple correct
A. It contains the source code for the project's dependencies.  <- candidate selected, marked WRONG
B. It contains documentation for the project's dependencies.    <- candidate selected, marked WRONG
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A + B  (marked Incorrect, 0/1)  
**Reality:** A is TRUE, B is FALSE. VERDICT = FALSE (the exam is wrong).

### Q37 — Section 8 of 12 — Protocols

`External ID: yisnw2In10` · Question 37 of 60 (1 of 4 in section) · [proof](test/proofs/s08_q37_protocols_polymorphism_test.exs)

```text
"Regarding Protocols in Elixir, which of the following statements are true?
 Pick all that apply."

Response type: Multiple correct
A. Protocols offer compile-time polymorphism
B. Protocols are impure interfaces
C. Protocols are pure interfaces          <- candidate selected
D. Protocols offer runtime polymorphism   <- candidate selected
E. Protocols are not interfaces
```

**Exam key:** A + C   (A shows a grey "correct, unselected" tick; C shows a  
**Candidate:** C + D  (marked Incorrect, 0/1)  
**Reality:** C + D is the correct set. VERDICT = FALSE (exam wrong).

### Q39 — Section 8 of 12 — Protocols

`External ID: aK8gykyYCR` · Question 39 of 60 (3 of 4 in section) · [proof](test/proofs/s08_q39_protocols_function_definitions_test.exs)

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

`External ID: z6CzVBScRLQ` · Question 41 of 60 (1 of 4 in section) · [proof](test/proofs/s09_q41_registry_exit_test.exs)

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

### Q46 — Section 10 of 12 — Streams

`External ID: AdHIcMLDKv` · Question 46 of 60 (2 of 2 in section) · [proof](test/proofs/s10_q46_streams_vs_enum_test.exs)

```text
"Which of the following statements is the correct way (optimal for
 computation/memory) of using Streams and Enums in Elixir?"

Response type: Multiple correct
A. 1..100_000 |> Enum.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum
B. 1..100_000 |> Stream.map(&(&1 * 3)) |> Stream.filter(odd?) |> Enum.sum
                                                    <- candidate answered, marked WRONG
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** B  (marked Incorrect, 0/1)  
**Reality:** B IS the optimal form. VERDICT = FALSE (the exam is wrong).

### Q48 — Section 11 of 12 — Supervisors

`External ID: tdFFQIDPPe` · Question 48 of 60 (2 of 10 in section) · [proof](test/proofs/s11_q48_supervise_os_processes_test.exs)

```text
"Can a Supervisor supervise non-Elixir processes such as external system
 processes or operating system threads?"

Response type: Multiple correct
A. Yes, but the Supervisor will not be able to shutdown external process.
                                                <- candidate selected, marked WRONG
B. Yes, but the Supervisor will have a limited control over external process.
                                                <- candidate selected, marked WRONG
```

**Exam key:** _not captured on the results screen — inferred_  
**Candidate:** A + B  (marked Incorrect, 0/1)  
**Reality:** BOTH A AND B DESCRIBE THE MEASURED BEHAVIOUR.

### Q54 — Section 11 of 12 — Supervisors

`External ID: DYoKKwfhjM` · Question 54 of 60 (8 of 10 in section) · [proof](test/proofs/s11_q54_supervisor_init_failure_test.exs)

```text
"Given the Supervisor running with `strategy: :one_for_one`. Its child
 process is a GenServer. The GenServer is started by a Supervisor, but
 GenServer's `init/1` callback raised an error. Which of the following
 statements describes what will happen to Supervisor?"

A. The Supervisor will then be terminated as well.            <- candidate answered
B. The Supervisor will attempt to restart the child process
   according to its restart strategy.                         <- exam marked correct
```

**Exam key:** B  
**Candidate:** A  (marked Incorrect, 0/1)  
**Reality:** A is correct. VERDICT = FALSE (the exam's marked answer is wrong).

<!-- END QUESTIONS -->

---

## Filing notes

* Quote the **External ID** (e.g. `DYoKKwfhjM`) — the certification body needs it
  to locate the question.
* Pin every claim to a version. "What Elixir does" is only meaningful against
  Elixir 1.19.1 / OTP 28, which the suite prints on every run.
* Lead with **Q54, Q37, Q46, Q5 and Q41** — those are unambiguous and independently
  verifiable. Q48 is equally solid on the facts but needs its full option list
  first. Conceding Q39 up front costs nothing and makes the rest credible.
* Where the verdict is "no correct option", the ask is for the question to be
  **voided**, not re-keyed to the candidate's answer.

Conventions for adding new proofs are in [AGENTS.md](AGENTS.md).
