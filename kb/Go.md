# Go Runtime Memory

## Memory Views

No single number describes Go process memory. Compare measurements that represent the same layer.

- **Live objects**: reachable Go heap objects after a completed GC.
- **Current heap objects**: allocated objects at the instant of observation; this can include unreachable objects not yet swept.
- **Heap spans**: pages owned by Go's allocator, including free slots and completely idle spans.
- **Go runtime memory**: heap spans plus stacks, metadata, profiling structures, and other runtime allocations.
- **RSS**: resident pages of the entire process, including Go runtime memory, executable and shared-library mappings, and application-created mappings.

`runtime/metrics` is the preferred detailed interface. `runtime.MemStats` and the standard Go Prometheus collector expose many of the same values.

## Heap Accounting

| `MemStats` field | Meaning |
| --- | --- |
| `HeapAlloc` | Current bytes in allocated heap objects. Equivalent to `/memory/classes/heap/objects:bytes`. Not necessarily post-GC live bytes. |
| `HeapInuse` | Bytes in spans currently in use by the allocator. Contains allocated objects and unused slots in non-idle spans. |
| `HeapIdle` | Heap spans not currently in use. |
| `HeapReleased` | Idle heap pages the runtime has returned to the OS. |
| `HeapSys` | Heap memory obtained from the OS; approximately `HeapInuse + HeapIdle`. |
| `StackSys` | Memory used by Go stacks and OS thread stacks. |
| `Sys` | Total memory obtained by the Go runtime across heap, stacks, metadata, profiling, and other runtime classes. |

Useful derived values:

```text
HeapInuse - HeapAlloc       unused slots in non-idle spans
HeapIdle - HeapReleased     idle heap retained by the runtime
Sys - HeapReleased          approximate Go runtime memory not released to the OS
```

The first two are non-negative. They are allocator state, not evidence of a leak by themselves.

## Garbage Collection And Heap Goals

Go uses a concurrent, tracing, non-compacting GC. It reclaims dead objects but does not relocate survivors to compact partially occupied spans.

`GOGC` controls the normal heap-growth target. Ignoring minimums and pacer adjustments:

```text
heap goal = live heap after the last GC * (1 + GOGC / 100)
```

With `GOGC=100`, the usual goal is approximately twice the prior post-GC live heap. The heap grows from that live baseline toward the goal as allocation proceeds; `HeapAlloc` therefore includes a current-cycle allocation set that may mostly be collected at the next GC.

- `NextGC` / `/gc/heap/goal:bytes` is the runtime's authoritative current heap goal.
- `/gc/heap/live:bytes` is the marked live heap from the previous GC and is the relevant input to the ordinary GOGC rule.
- When a memory limit is not constraining the goal, `NextGC / (1 + GOGC/100)` estimates that live heap if the live-heap metric is unavailable.
- The ordinary allocation headroom before starting the next GC is approximately `live heap * GOGC/100`, or `NextGC - live heap`. It is not based on `HeapInuse`.
- Lower `GOGC` reduces the normal heap envelope and increases GC frequency and CPU work.
- `GOGC=off` disables growth-based triggering, but does not disable GC triggered by a memory limit or explicit calls.

The allocator may retain and reuse spans after a GC. A stable post-GC live heap can therefore coexist with an RSS that rises toward the process's steady-state allocator envelope.

## GOMEMLIMIT

`GOMEMLIMIT` is a soft limit on Go-runtime-managed memory, not a hard RSS limit and not a live-heap limit.

- It constrains the pacer's heap goal and increases GC/scavenging pressure.
- It includes Go-managed heap and runtime overhead, but excludes memory Go does not manage, such as arbitrary `mmap` allocations and most process image mappings.
- It cannot compact partially occupied spans.
- The runtime may temporarily exceed it and may run GC very frequently if the configured limit is too close to the irreducible live set.
- If the ordinary GOGC-derived `NextGC` is below the limit-derived goal, `GOGC`, not `GOMEMLIMIT`, is controlling the current heap goal.

`Sys - HeapReleased` is a useful approximation of Go-managed, non-released memory for reasoning about the limit. It is not an RSS measurement.

## Heap Profiles

The heap profile reports sampled, allocation-site-attributed heap objects. It is not a direct memory-accounting snapshot.

- `inuse_space` estimates bytes allocated at sites whose objects are in use in the published profile.
- `alloc_space` estimates cumulative allocated bytes at those sites.
- The default sampling rate is 512 KiB: `MemProfileRate = 512 * 1024`. Profile totals are estimates.
- The runtime intentionally publishes heap-profile data up to two GC cycles late. It delays allocation and sweep-free accounting to produce a consistent profile.
- At high allocation rates, `inuse_space` can be substantially lower than same-instant `HeapAlloc` without a leak or profiler defect.
- Heap profiles do not account for idle span space, free slots in active spans, goroutine stacks, GC metadata, span metadata, or other non-heap runtime allocations.

When comparing profile and runtime values, account for GC-cycle delay and sampling. The delay is measured in GC cycles, not a fixed byte count.

- `TotalAlloc / NumGC` is only a historical average allocation volume per GC; it is not the cycle's exact allocation budget.
- `live heap * GOGC/100` is the ordinary pre-GC allocation headroom, not total allocations during a completed cycle.
- Allocations continue while GC runs, and pacer adjustments or a memory limit can change the goal.
- To measure exact allocation volume for a particular cycle, record `TotalAlloc` (or `/gc/heap/allocs:bytes`) at consecutive GC-cycle boundaries and take the delta.

## Scavenging And RSS

Go's scavenger can return completely idle heap pages to the OS. It cannot release a span that still contains live allocations.

- `HeapReleased` tracks idle heap pages released by the runtime.
- On Linux in Go 1.26, the default is `MADV_DONTNEED`, selected by `GODEBUG=madvdontneed=1`. Released pages should generally leave RSS promptly.
- `GODEBUG=madvdontneed=0` selects `MADV_FREE`; pages may remain resident until kernel reclaim.
- RSS can still differ from Go metrics because it includes mappings outside Go's accounting and because mapped pages need not be resident.

Pure Go does not guarantee that all memory is visible in heap profiles or `MemStats`: packages can create file or anonymous mappings through OS syscalls.

## Investigation Workflow

Use a time series and compare values at comparable GC phases.

```text
HeapAlloc
HeapInuse - HeapAlloc
HeapIdle - HeapReleased
HeapSys
Sys - HeapReleased
NextGC
StackSys, MSpanSys, GCSys, BuckHashSys
RSS and process mappings
```

- Rising post-GC live heap or rising `HeapAlloc` at equivalent GC phases suggests retained heap objects.
- Rising `HeapInuse - HeapAlloc` suggests growing slack in active spans.
- Rising `HeapIdle - HeapReleased` suggests retained reusable heap or delayed scavenging.
- Flat Go-runtime metrics with rising RSS requires inspecting process mappings, for example `/proc/<pid>/smaps_rollup` on Linux.
- A stable delayed heap profile alone does not prove current `HeapAlloc`, allocator spans, or RSS are stable.
