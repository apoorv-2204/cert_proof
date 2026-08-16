# Elixir Online Advanced Exam 2025 — Questions Answered Correctly but Marked Wrong

Executable evidence for five questions on the *Elixir Online Advanced Exam 2025*
where **the candidate's answer was correct and the exam's key was wrong**. Every
claim here is proved by a runnable test, not by argument.

**Verified on Elixir 1.19.1 / Erlang OTP 28 (erts-16.1.1), Linux.**

```sh
mix deps.get
mix test          # all proofs, including test/answered_wrong/
```

Each question has one file in [test/proofs/](test/proofs/), named
`s<SECTION>_q<QUESTION>_<topic>_test.exs`, opening with the question text, the
exam's key, and the measured truth.

> Questions where the candidate's answer was *also* wrong live separately in
> [OTHER_DISPUTES.md](OTHER_DISPUTES.md) and [test/answered_wrong/](test/answered_wrong/).
> Several of those are still errors in the exam — but they are void-the-question
> arguments, not marks to reclaim.

---

## The five marks to reclaim

| Q | Section | Candidate's answer | Why it stands |
|---|---|---|---|
| 5 | 2 — Distribution | B — useless PID + warning | verbatim the Erlang doc for `spawn_link/2`; both halves observed |
| 37 | 8 — Protocols | C + D | protocols are runtime polymorphic; the key swaps A and D |
| 46 | 10 — Streams | B — fully lazy pipeline | wins on both axes the question names |
| 48 | 11 — Supervisors | A + B — "yes, limited control" | the OS process outlives the supervisor — confirm the full option list first |
| 54 | 11 — Supervisors | A — supervisor terminated too | the restart strategy is never consulted at start-up |

---

## The disputes

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

---

## Filing notes

* Quote the **External ID** (e.g. `DYoKKwfhjM`) — the certification body needs it
  to locate the question.
* Pin every claim to a version. "What Elixir does" is only meaningful against
  Elixir 1.19.1 / OTP 28, which the suite prints on every run.
* Lead with **Q54, Q37 and Q46** — those are unambiguous and independently
  verifiable. Q5 is equally solid. Q48 needs its full option list first.
* Only two keys were actually visible on the results screens (Q37 and Q54);
  the rest are inferred from "your selection is marked wrong". Where a write-up
  says *inferred*, confirm it before filing.

Conventions for adding new proofs are in [AGENTS.md](AGENTS.md).

---

<!-- BEGIN QUESTIONS (generated by sync_readme_questions.py) -->

## Questions verbatim

Copied from the proof files' moduledocs — the wording there is the source
of truth. Regenerate with `python3 sync_readme_questions.py`.

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
