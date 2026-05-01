# Neptune.jl

**Neptune is a non-reactive Julia notebook**, forked from [Pluto.jl](https://github.com/JuliaPluto/Pluto.jl).

It looks and works exactly like Pluto, with one key difference: **cells do not automatically re-run when other cells change**. You decide when each cell runs, just like in Jupyter.

---

## What is the difference from Pluto?

Pluto is a *reactive* notebook: if cell B uses a variable defined by cell A, editing cell A automatically re-runs cell B (and anything downstream). This is a deliberate design choice that makes Pluto notebooks reproducible and stateless.

Neptune removes that behaviour. In Neptune:

- Editing a cell runs **only that cell**.
- Cells **do not run automatically** when you open a saved notebook.
- Multiple cells can **define the same variable** without error.
- Everything else — the UI, package management, `@bind` widgets, exports — is identical to Pluto.

This makes Neptune better suited to workflows where:
- Cells are **expensive to compute** (ML training, simulations) and you don't want them re-running unexpectedly.
- You are **iterating on one cell** and don't want downstream cells to run until you're ready.
- You want **Jupyter-style control** with a cleaner UI than Jupyter.

---

## Install

Start Julia and run:

```julia
import Pkg
Pkg.add(url="https://github.com/compleathorseplayer/Neptune.jl")
```

---

## Usage

```julia
using Neptune
Neptune.run()
```

This opens the Neptune interface in your browser. Create a new notebook or open an existing one (including `.jl` notebooks saved by Pluto — Neptune can open both formats).

---

## Relationship to Pluto

Neptune is a close fork of Pluto.jl v0.20.24. The changes are minimal and targeted:

1. Cells only run when explicitly requested — no reactive propagation to downstream cells.
2. Notebooks do not auto-run all cells on open.
3. Multiple cells may define the same variable.

All credit for the underlying notebook platform goes to [Fons van der Plas](https://github.com/fonsp) and the Pluto.jl contributors. Neptune exists solely to serve workflows where reactivity is a hindrance rather than a help.
