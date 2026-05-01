# Maintaining Neptune.jl

This document explains how to update Neptune when a new version of Pluto.jl is released.

Neptune is a minimal fork of Pluto. The goal is to keep the diff as small as possible so that re-forking from a new Pluto release is straightforward.

---

## What Neptune changes from Pluto

There are four targeted changes. Everything else is a rename.

### 1. `src/Configuration.jl` — disable auto-run on load

```julia
# Pluto default:
const RUN_NOTEBOOK_ON_LOAD_DEFAULT = true

# Neptune change:
const RUN_NOTEBOOK_ON_LOAD_DEFAULT = false
```

Prevents all cells from executing automatically when a saved notebook is opened.

### 2. `src/evaluation/Run.jl` — disable reactive propagation

Inside `run_reactive_core!`, immediately after `to_run` is computed, add:

```julia
# Neptune: non-reactive mode — only execute explicitly-requested cells, not downstream dependents
roots_set = Set(roots)
to_run = filter(c -> c ∈ roots_set, to_run)
```

This is the core change. `roots` contains only the cells the user explicitly ran.
Without this filter, Pluto expands `to_run` to include all downstream-dependent cells.

### 3. `src/evaluation/Run.jl` — allow multiple definitions

In the same function, the two `topological_order_cached` calls must include `allow_multiple_defs=true`:

```julia
old_order = topological_order_cached(old_topology, roots; allow_multiple_defs=true)
# ...
new_order = topological_order_cached(new_topology, new_roots; allow_multiple_defs=true)
```

Without this, Neptune raises an error if two cells define the same variable — a Pluto
restriction that doesn't apply in a non-reactive setting.

### 4. `src/Neptune.jl` — extend the PlutoDependencyExplorer import

Add `DEFAULT_PRECEDENCE_HEURISTIC` and `FunctionName` to the import line:

```julia
import PlutoDependencyExplorer: ..., DEFAULT_PRECEDENCE_HEURISTIC, FunctionName
```

These are used in `Run.jl` but were not explicitly imported (Pluto imported them
via a different mechanism). Without this, creating a new notebook crashes with
`UndefVarError: DEFAULT_PRECEDENCE_HEURISTIC`.

---

## Step-by-step: re-forking from a new Pluto release

### 1. Clone the new Pluto

```bash
git clone --depth=1 --filter=blob:none https://github.com/JuliaPluto/Pluto.jl.git /path/to/Neptune
cd /path/to/Neptune
```

### 2. Update `Project.toml`

```toml
name = "Neptune"
uuid = "6741aa20-66dc-42c8-a8ae-3740631035cd"   # must not change — registry key
license = "MIT"
version = "0.X.0"                                # must exceed the last registered version
authors = ["David Edelman <compleathorseplayer@gmail.com>"]
```

The UUID **must** stay as `6741aa20-66dc-42c8-a8ae-3740631035cd` to match the Julia
General Registry entry. Check the last registered version at
https://github.com/JuliaRegistries/General/tree/master/N/Neptune and set the new
version one minor bump higher.

### 3. Rename Pluto → Neptune in Julia source files

```bash
find src -name "*.jl" | while IFS= read -r f; do
    perl -i -pe 's/\bPluto\b/Neptune/g' "$f"
done
```

The word-boundary pattern `\bPluto\b` safely leaves `PlutoRunner` and
`PlutoDependencyExplorer` unchanged.

Then fix any GitHub issue URLs that got incorrectly renamed:

```bash
find src -name "*.jl" | while IFS= read -r f; do
    perl -i -pe 's|fonsp/Neptune\.jl|fonsp/Pluto.jl|g' "$f"
done
```

Rename the main module file:

```bash
mv src/Pluto.jl src/Neptune.jl
```

### 4. Rename Pluto → Neptune in frontend files

```bash
find frontend -type f | while IFS= read -r f; do
    perl -i -pe 's/\bPluto\b/Neptune/g' "$f"
done
```

The SVG logo (`frontend/img/logo.svg`) has "Pluto" baked in as vector paths and
cannot be renamed this way. Neptune hides the logo images via CSS and renders
"Neptune.jl" as text instead — this is handled in `frontend/editor.css`:

```css
nav#at_the_top img#logo-small,
nav#at_the_top img#logo-big {
    display: none;
}
nav#at_the_top h1::before {
    content: "🔱 Neptune.jl";
    font-size: 1.4rem;
    font-weight: 700;
    letter-spacing: -0.5px;
}
```

### 5. Apply the four functional changes

Make the four changes listed in the first section of this document.

To locate the right place in `Run.jl`, search for:
- `RUN_NOTEBOOK_ON_LOAD_DEFAULT` in `Configuration.jl`
- `to_run = filter` comment marker in `Run.jl` (if carrying forward from a previous Neptune)
- `topological_order_cached(old_topology, roots)` and `topological_order_cached(new_topology, new_roots)` in `run_reactive_core!`
- The `import PlutoDependencyExplorer:` line in `Neptune.jl`

### 6. Apply notebook format compatibility patch

Neptune should be able to open notebooks saved by Pluto. In
`src/notebook/saving and loading.jl`, find the header check and accept both headers:

```julia
if firstline != _notebook_header && firstline != "### A Pluto.jl notebook ###"
    error(...)
end
```

### 7. Fix the notebook save directory

In `src/notebook/path helpers.jl`:

```julia
# Change:
"JULIA_PLUTO_NEW_NOTEBOOKS_DIR",
joinpath(first(DEPOT_PATH), "pluto_notebooks")

# To:
"JULIA_NEPTUNE_NEW_NOTEBOOKS_DIR",
joinpath(first(DEPOT_PATH), "neptune_notebooks")
```

### 8. Smoke-test

```bash
julia --project=. -e '
using Neptune
session = Neptune.ServerSession()
nb = Neptune.SessionActions.new(session; run_async=false)
println("OK: ", nb.path)
'
```

If this prints `OK: ...` without errors, the basic plumbing works.

Then start the server and manually verify:
1. Create a notebook with two cells — cell A defines `x = 1`, cell B computes `y = x + 1`.
2. Edit cell A to `x = 2` and run it.
3. Confirm cell B does **not** re-run automatically.

### 9. Commit and push

```bash
git add -A
git commit -m "Fork Pluto.jl vX.Y.Z as Neptune vA.B.C: non-reactive mode"
git push origin main
```

### 10. Register the new version

Post a comment on the latest commit on GitHub:

```
@JuliaRegistrator register
```

This triggers an automated PR to the Julia General Registry. Once merged
(usually within a few hours), the new version is available via `Pkg.add("Neptune")`.

---

## Files that need attention on each re-fork

| File | What to check |
|---|---|
| `src/Neptune.jl` | `import PlutoDependencyExplorer:` line — add any new symbols used in `Run.jl` |
| `src/Configuration.jl` | `RUN_NOTEBOOK_ON_LOAD_DEFAULT` — must be `false` |
| `src/evaluation/Run.jl` | The `to_run` filter and `allow_multiple_defs=true` — may need repositioning if Pluto refactored `run_reactive_core!` |
| `src/notebook/saving and loading.jl` | The header check — must accept `### A Pluto.jl notebook ###` |
| `src/notebook/path helpers.jl` | Notebook save directory |
| `frontend/editor.css` | Logo CSS override |
| `Project.toml` | UUID (never change), version (always bump), name, authors |
