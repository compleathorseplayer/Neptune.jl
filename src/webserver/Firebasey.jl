### A Neptune.jl notebook ###
# v0.20.4

using Markdown
using InteractiveUtils

# ╔═╡ e748600a-2de1-11eb-24be-d5f0ecab8fa4
# ╠═╡ show_logs = false
# ╠═╡ skip_as_script = true
#=╠═╡
# Only define this in Neptune - assume we are `using Test` otherwise
begin
	import Pkg
	Pkg.activate(mktempdir())
	Pkg.add(Pkg.PackageSpec(name="PlutoTest"))
	using PlutoTest
end
  ╠═╡ =#

# ╔═╡ 3e07f976-6cd0-4841-9762-d40337bb0645
# ╠═╡ skip_as_script = true
#=╠═╡
using Markdown: @md_str
  ╠═╡ =#

# ╔═╡ d948dc6e-2de1-11eb-19e7-cb3bb66353b6
# ╠═╡ skip_as_script = true
#=╠═╡
md"# Diffing"
  ╠═╡ =#

# ╔═╡ 1a6e1853-6db1-4074-bce0-5f274351cece
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
We define a _diffing system_ for Julia `Dict`s, which is analogous to the diffing system of immer.js.

This notebook is part of Neptune's source code (included in `src/webserver/Dynamic.jl`).
"""
  ╠═╡ =#

# ╔═╡ 49fc1f97-3b8f-4297-94e5-2e24c001d35c
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
## Example

Computing a diff:
"""
  ╠═╡ =#

# ╔═╡ d8e73b90-24c5-4e50-830b-b1dbe6224c8e
# ╠═╡ skip_as_script = true
#=╠═╡
dict_1 = Dict{String,Any}(
	"a" => 1,
	"b" => Dict(
		"c" => [3,4],
		"d" => 99,
	),
	"e" => "hello!"
);
  ╠═╡ =#

# ╔═╡ 19646596-b35b-44fa-bfcf-891f9ffb748c
# ╠═╡ skip_as_script = true
#=╠═╡
dict_2 = Dict{String,Any}(
	"a" => 1,
	"b" => Dict(
		"c" => [3,4,5],
		"d" => 99,
		"🏝" => "👍",
	),
);
  ╠═╡ =#

# ╔═╡ 9d2c07d9-16a9-4b9f-a375-2adb6e5b907a
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
Applying a set of patches:
"""
  ╠═╡ =#

# ╔═╡ 336bfd4f-8a8e-4a2d-be08-ee48d6a9f747
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
## JSONPatch objects
"""
  ╠═╡ =#

# ╔═╡ db116c0a-2de1-11eb-2a56-872af797c547
abstract type JSONPatch end

# ╔═╡ bd0d46bb-3e58-4522-bae0-83eb799196c4
const PatchPath = Vector

# ╔═╡ db2d8a3e-2de1-11eb-02b8-9ffbfaeff61c
struct AddPatch <: JSONPatch
	path::PatchPath
	value::Any
end

# ╔═╡ ffe9b3d9-8e35-4a31-bab2-8787a4140594
struct RemovePatch <: JSONPatch
	path::PatchPath
end

# ╔═╡ 894de8a7-2757-4d7a-a2be-1069fa872911
struct ReplacePatch <: JSONPatch
	path::PatchPath
	value::Any
end

# ╔═╡ 9a364714-edb1-4bca-9387-a8bbacccd10d
struct CopyPatch <: JSONPatch
	path::PatchPath
	from::PatchPath
end

# ╔═╡ 9321d3be-cb91-4406-9dc7-e5c38f7d377c
struct MovePatch <: JSONPatch
	path::PatchPath 
	from::PatchPath
end

# ╔═╡ 73631aea-5e93-4da2-a32d-649029660d4e
const Patches = Vector{JSONPatch}

# ╔═╡ 0fd3e910-abcc-4421-9d0b-5cfb90034338
const NoChanges = Patches()

# ╔═╡ aad7ab32-eecf-4aad-883d-1c802cad6c0c
# ╠═╡ skip_as_script = true
#=╠═╡
md"### =="
  ╠═╡ =#

# ╔═╡ 732fd744-acdb-4507-b1de-6866ec5563dd
Base.hash(a::AddPatch, h::UInt) = hash((AddPatch, a.value, a.path), h)

# ╔═╡ 17606cf6-2d0f-4245-89a3-746ad818a664
Base.hash(a::RemovePatch, h::UInt) = hash((RemovePatch, a.path), h)

# ╔═╡ c7ac7d27-7bf9-4209-8f3c-e4d52c543e29
Base.hash(a::ReplacePatch, h::UInt) = hash((ReplacePatch, a.value, a.path), h)

# ╔═╡ 042f7788-e996-430e-886d-ffb4f70dea9e
Base.hash(a::CopyPatch, h::UInt) = hash((CopyPatch, a.from, a.path), h)

# ╔═╡ 9d2dde5c-d404-4fbc-b8e0-5024303c8052
Base.hash(a::MovePatch, h::UInt) = hash((MovePatch, a.from, a.path), h)

# ╔═╡ f649f67c-aab0-4d35-a799-f398e5f3ecc4
function Base.:(==)(a::AddPatch, b::AddPatch)
	a.value == b.value && a.path == b.path
end

# ╔═╡ 63087738-d70c-46f5-b072-21cd8953df35
function Base.:(==)(a::RemovePatch, b::RemovePatch)
	a.path == b.path
end

# ╔═╡ aa81974a-7254-45e0-9bfe-840c4793147f
function Base.:(==)(a::ReplacePatch, b::ReplacePatch)
	a.path == b.path && a.value == b.value
end

# ╔═╡ 31188a03-76ba-40cf-a333-4d339ce37711
function Base.:(==)(a::CopyPatch, b::CopyPatch)
	a.path == b.path && a.from == b.from
end

# ╔═╡ 7524a9e8-1a6d-4851-b50e-19415f25a84b
function Base.:(==)(a::MovePatch, b::MovePatch)
	a.path == b.path && a.from == b.from
end

# ╔═╡ 5ddfd616-db20-451b-bc1e-2ad52e0e2777
#=╠═╡
@test Base.hash(ReplacePatch(["asd"], Dict("a" => 2))) == 
		Base.hash(ReplacePatch(["asd"], Dict("a" => 2)))
  ╠═╡ =#

# ╔═╡ 24e93923-eab9-4a7b-9bc7-8d8a1209a78f
#=╠═╡
@test ReplacePatch(["asd"], Dict("a" => 2)) == 
		ReplacePatch(["asd"], Dict("a" => 2))
  ╠═╡ =#

# ╔═╡ 09ddf4d9-5ccb-4530-bfab-d11b864e872a
#=╠═╡
@test Base.hash(RemovePatch(["asd"])) == Base.hash(RemovePatch(["asd"]))
  ╠═╡ =#

# ╔═╡ d9e764db-94fc-44f7-8c2e-3d63f4809617
#=╠═╡
@test RemovePatch(["asd"]) == RemovePatch(["asd"])
  ╠═╡ =#

# ╔═╡ 99df99ad-aad5-4275-97d4-d1ceeb2f8d15
#=╠═╡
@test Base.hash(RemovePatch(["aasd"])) != Base.hash(RemovePatch(["asd"]))
  ╠═╡ =#

# ╔═╡ 2d665639-7274-495a-ae9d-f358a8219bb7
#=╠═╡
@test Base.hash(ReplacePatch(["asd"], Dict("a" => 2))) != 
		Base.hash(AddPatch(["asd"], Dict("a" => 2)))
  ╠═╡ =#

# ╔═╡ f658a72d-871d-49b3-9b73-7efedafbd7a6
# ╠═╡ skip_as_script = true
#=╠═╡
md"### convert(::Type{Dict}, ::JSONPatch)"
  ╠═╡ =#

# ╔═╡ 230bafe2-aaa7-48f0-9fd1-b53956281684
function Base.convert(::Type{Dict}, patch::AddPatch)
	Dict{String,Any}("op" => "add", "path" => patch.path, "value" => patch.value)
end

# ╔═╡ b48e2c08-a94a-4247-877d-949d92dde626
function Base.convert(::Type{Dict}, patch::RemovePatch)
	Dict{String,Any}("op" => "remove", "path" => patch.path)
end

# ╔═╡ 921a130e-b028-4f91-b077-3bd79dcb6c6d
function Base.convert(::Type{JSONPatch}, patch_dict::Dict)
	op = patch_dict["op"]
	if op == "add"
		AddPatch(patch_dict["path"], patch_dict["value"])
	elseif op == "remove"
		RemovePatch(patch_dict["path"])
	elseif op == "replace"
		ReplacePatch(patch_dict["path"], patch_dict["value"])
	else
		throw(ArgumentError("Unknown operation :$(patch_dict["op"]) in Dict to JSONPatch conversion"))
	end
end

# ╔═╡ 07eeb122-6706-4544-a007-1c8d6581eec8
# ╠═╡ skip_as_script = true
#=╠═╡
Base.convert(Dict, AddPatch([:x, :y], 10))
  ╠═╡ =#

# ╔═╡ c59b30b9-f702-41f1-bb2e-1736c8cd5ede
# ╠═╡ skip_as_script = true
#=╠═╡
Base.convert(Dict, RemovePatch([:x, :y]))
  ╠═╡ =#

# ╔═╡ 6d67f8a5-0e0c-4b6e-a267-96b34d580946
# ╠═╡ skip_as_script = true
#=╠═╡
add_patch = AddPatch(["counter"], 10)
  ╠═╡ =#

# ╔═╡ 56b28842-4a67-44d7-95e7-55d457a44fb1
# ╠═╡ skip_as_script = true
#=╠═╡
remove_patch = RemovePatch(["counter"])
  ╠═╡ =#

# ╔═╡ f10e31c0-1d2c-4727-aba5-dd676a10041b
# ╠═╡ skip_as_script = true
#=╠═╡
replace_patch = ReplacePatch(["counter"], 10)
  ╠═╡ =#

# ╔═╡ 3a99e22d-42d6-4b2d-9381-022b41b0e852
# ╠═╡ skip_as_script = true
#=╠═╡
md"### wrappath"
  ╠═╡ =#

# ╔═╡ 831d84a6-1c71-4e68-8c7c-27d9093a82c4
function wrappath(path::PatchPath, patches::Vector{JSONPatch})
	map(patches) do patch
		wrappath(path, patch)
	end
end

# ╔═╡ 2ad11c73-4691-4283-8f98-3d2a87926b99
function wrappath(path, patch::AddPatch)
	AddPatch([path..., patch.path...], patch.value)
end

# ╔═╡ 5513ea3b-9498-426c-98cb-7dc23d32f72e
function wrappath(path, patch::RemovePatch)
	RemovePatch([path..., patch.path...])
end

# ╔═╡ 0c2d6da1-cad3-4c9f-93e9-922457083945
function wrappath(path, patch::ReplacePatch)
	ReplacePatch([path..., patch.path...], patch.value)
end

# ╔═╡ 84c87031-7733-4d1f-aa90-f8ab71506251
function wrappath(path, patch::CopyPatch)
	CopyPatch([path..., patch.path...], patch.from)
end

# ╔═╡ 8f265a33-3a2d-4508-9477-ca62e8ce3c12
function wrappath(path, patch::MovePatch)
	MovePatch([path..., patch.path...], patch.from)
end

# ╔═╡ daf9ec12-2de1-11eb-3a8d-59d9c2753134
# ╠═╡ skip_as_script = true
#=╠═╡
md"## Diff"
  ╠═╡ =#

# ╔═╡ 0b50f6b2-8e85-4565-9f04-f99c913b4592
const use_triple_equals_for_arrays = Ref(false)

# ╔═╡ 59e94cb2-c2f9-4f6c-9562-45e8c15931af
function diff(old::T, new::T) where T <: AbstractArray
	if use_triple_equals_for_arrays[] ? 
		((old === new) || (old == new)) : 
		(old == new)
		NoChanges
	else
		JSONPatch[ReplacePatch([], new)]
	end
end

# ╔═╡ c9d5d81c-b0b6-4d1a-b1de-96d3b3701700
function diff(old::T, new::T) where T
	if old == new
		NoChanges
	else
		JSONPatch[ReplacePatch([], new)]
	end
end

# ╔═╡ 24389a0a-c3ac-4438-9dfe-1d14cd033d25
diff(::Missing, ::Missing) = NoChanges

# ╔═╡ 9cbaaec2-709c-4769-886c-ec92b12c18bc
struct Deep{T} value::T end

# ╔═╡ db75df12-2de1-11eb-0726-d1995cebd382
function diff(old::Deep{T}, new::Deep{T}) where T
	changes = JSONPatch[]
	for property in propertynames(old.value)
		for change in diff(getproperty(old.value, property), getproperty(new.value, property))
			push!(changes, wrappath([property], change))
		end
	end
	changes
	
	# changes = []
	# for property in fieldnames(T)
	# 	for change in diff(getfield(old.value, property), getfield(new.value, property))
	# 		push!(changes, wrappath([property], change))
	# 	end
	# end
	# changes
end

# ╔═╡ dbc7f97a-2de1-11eb-362f-055a734d1a9e
function diff(o1::AbstractDict, o2::AbstractDict)
	changes = JSONPatch[]
	# for key in keys(o1) ∪ keys(o2)
	# 	for change in diff(get(o1, key, nothing), get(o2, key, nothing))
	# 		push!(changes, wrappath([key], change))
	# 	end
	# end
	
	# same as above but faster:
	
	for (key1, val1) in o1
		for change in diff(val1, get(o2, key1, nothing))
			push!(changes, wrappath([key1], change))
		end
	end
	for (key2, val2) in o2
		if !haskey(o1, key2)
			for change in diff(nothing, val2)
				push!(changes, wrappath([key2], change))
			end
		end
	end
	changes
end

# ╔═╡ 67ade214-2de3-11eb-291d-135a397d629b
function diff(o1, o2)
	JSONPatch[ReplacePatch([], o2)]
end

# ╔═╡ b8c58aa4-c24d-48a3-b2a8-7c01d50a3349
function diff(o1::Nothing, o2)
	JSONPatch[AddPatch([], o2)]
end

# ╔═╡ 5ab390f9-3b0c-4978-9e21-2aaa61db2ce4
function diff(o1, o2::Nothing)
	JSONPatch[RemovePatch([])]
end

# ╔═╡ 09f53db0-21ae-490b-86b5-414eba403d57
function diff(o1::Nothing, o2::Nothing)
	NoChanges
end

# ╔═╡ 7ca087b8-73ac-49ea-9c5a-2971f0da491f
#=╠═╡
example_patches = diff(dict_1, dict_2)
  ╠═╡ =#

# ╔═╡ 59b46bfe-da74-43af-9c11-cb0bdb2c13a2
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
### Dict example
"""
  ╠═╡ =#

# ╔═╡ 200516da-8cfb-42fe-a6b9-cb4730168923
# ╠═╡ skip_as_script = true
#=╠═╡
celldict1 = Dict(:x => 1, :y => 2, :z => 3)
  ╠═╡ =#

# ╔═╡ 76326e6c-b95a-4b2d-a78c-e283e5fadbe2
# ╠═╡ skip_as_script = true
#=╠═╡
celldict2 = Dict(:x => 1, :y => 2, :z => 4)
  ╠═╡ =#

# ╔═╡ 664cd334-91c7-40dd-a2bf-0da720307cfc
# ╠═╡ skip_as_script = true
#=╠═╡
notebook1 = Dict(
	:x => 1,
	:y => 2,
)
  ╠═╡ =#

# ╔═╡ b7fa5625-6178-4da8-a889-cd4f014f43ba
# ╠═╡ skip_as_script = true
#=╠═╡
notebook2 = Dict(
	:y => 4,
	:z => 5
)
  ╠═╡ =#

# ╔═╡ dbdd1df0-2de1-11eb-152f-8d1af1ad02fe
#=╠═╡
notebook1_to_notebook2 = diff(notebook1, notebook2)
  ╠═╡ =#

# ╔═╡ 3924953f-787a-4912-b6ee-9c9d3030f0f0
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
### Large Dict example 1
"""
  ╠═╡ =#

# ╔═╡ 80689881-1b7e-49b2-af97-9e3ab639d006
# ╠═╡ skip_as_script = true
#=╠═╡
big_array = rand(UInt8, 1_000_000)
  ╠═╡ =#

# ╔═╡ fd22b6af-5fd2-428a-8291-53e223ea692c
# ╠═╡ skip_as_script = true
#=╠═╡
big_string = repeat('a', 1_000_000);
  ╠═╡ =#

# ╔═╡ bcd5059b-b0d2-49d8-a756-92349aa56aca
#=╠═╡
large_dict_1 = Dict{String,Any}(
	"cell_$(i)" => Dict{String,Any}(
		"x" => 1,
		"y" => big_array,
		"z" => big_string,
	)
	for i in 1:10
);
  ╠═╡ =#

# ╔═╡ e7fd6bab-c114-4f3e-b9ad-1af2d1147770
#=╠═╡
begin
	large_dict_2 = Dict{String,Any}(
		"cell_$(i)" => Dict{String,Any}(
			"x" => 1,
			"y" => big_array,
			"z" => big_string,
		)
		for i in 1:10
	)
	large_dict_2["cell_5"]["y"] = [2,20]
	delete!(large_dict_2, "cell_2")
	large_dict_2["hello"] = Dict("a" => 1, "b" => 2)
	large_dict_2
end;
  ╠═╡ =#

# ╔═╡ 43c36ab7-e9ac-450a-8abe-435412f2be1d
#=╠═╡
diff(large_dict_1, large_dict_2)
  ╠═╡ =#

# ╔═╡ 1cf22fe6-4b58-4220-87a1-d7a18410b4e8
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
With `===` comparison for arrays:
"""
  ╠═╡ =#

# ╔═╡ ffb01ab4-e2e3-4fa4-8c0b-093d2899a536
# ╠═╡ skip_as_script = true
#=╠═╡
md"""
### Large Dict example 2
"""
  ╠═╡ =#

# ╔═╡ 8188de75-ae6e-48aa-9495-111fd27ffd26
# ╠═╡ skip_as_script = true
#=╠═╡
many_items_1 = Dict{String,Any}(
	"cell_$(i)" => Dict{String,Any}(
		"x" => 1,
		"y" => [2,3],
		"z" => "four",
	)
	for i in 1:100
)
  ╠═╡ =#

# ╔═╡ fdc427f0-dfe8-4114-beca-48fc15434534
#=╠═╡
@test isempty(diff(many_items_1, many_items_1))
  ╠═╡ =#

# ╔═╡ d807195e-ba27-4015-92a7-c9294d458d47
#=╠═╡
begin
	many_items_2 = deepcopy(many_items_1)
	many_items_2["cell_5"]["y"][2] = 20
	delete!(many_items_2, "cell_2")
	many_items_2["hello"] = Dict("a" => 1, "b" => 2)
	many_items_2
end
  ╠═╡ =#

# ╔═╡ 2e91a1a2-469c-4123-a0d7-3dcc49715738
#=╠═╡
diff(many_items_1, many_items_2)
  ╠═╡ =#

# ╔═╡ b8061c1b-dd03-4cd1-b275-90359ae2bb39
fairly_equal(a,b) = Set(a) == Set(b)

# ╔═╡ 2983f6d4-c1ca-4b66-a2d3-f858b0df2b4c
#=╠═╡
@test fairly_equal(diff(large_dict_1, large_dict_2), [
	ReplacePatch(["cell_5","y"], [2,20]),
	RemovePatch(["cell_2"]),
	AddPatch(["hello"], Dict("b" => 2, "a" => 1)),
])
  ╠═╡ =#

# ╔═╡ 61b81430-d26e-493c-96da-b6818e58c882
#=╠═╡
@test fairly_equal(diff(many_items_1, many_items_2), [
	ReplacePatch(["cell_5","y"], [2,20]),
	RemovePatch(["cell_2"]),
	AddPatch(["hello"], Dict("b" => 2, "a" => 1)),
])
  ╠═╡ =#

# ╔═╡ aeab3363-08ba-47c2-bd33-04a004ed72c4
#=╠═╡
diff(many_items_1, many_items_1)
  ╠═╡ =#

# ╔═╡ 62de3e79-4b4e-41df-8020-769c3c255c3e
#=╠═╡
@test isempty(diff(many_items_1, many_items_1))
  ╠═╡ =#

# ╔═╡ c7de406d-ccfe-41cf-8388-6bd2d7c42d64
# ╠═╡ skip_as_script = true
#=╠═╡
md"### Struct example"
  ╠═╡ =#

# ╔═╡ b9cc11ae-394b-44b9-bfbe-541d7720ead0
# ╠═╡ skip_as_script = true
#=╠═╡
struct Cell
	id
	code
	folded
end
  ╠═╡ =#

# ╔═╡ c3c675be-9178-4176-afe0-30501786b72c
#=╠═╡
deep_diff(old::Cell, new::Cell) = diff(Deep(old), Deep(new))
  ╠═╡ =#

# ╔═╡ 02585c72-1d92-4526-98c2-1ca07aad87a3
#=╠═╡
function direct_diff(old::Cell, new::Cell)
	changes = []
	if old.id ≠ new.id
		push!(changes, ReplacePatch([:id], new.id))
	end
	if old.code ≠ new.code
		push!(changes, ReplacePatch([:code], new.code))
	end
	if old.folded ≠ new.folded
		push!(changes, ReplacePatch([:folded], new.folded))
	end
	changes
end
  ╠═╡ =#

# ╔═╡ 2d084dd1-240d-4443-a8a2-82ae6e0b8900
# ╠═╡ skip_as_script = true
#=╠═╡
cell1 = Cell(1, 2, 3)
  ╠═╡ =#

# ╔═╡ 3e05200f-071a-4ebe-b685-ff980f07cde7
# ╠═╡ skip_as_script = true
#=╠═╡
cell2 = Cell(1, 2, 4)
  ╠═╡ =#

# ╔═╡ dd312598-2de1-11eb-144c-f92ed6484f5d
# ╠═╡ skip_as_script = true
#=╠═╡
md"## Update"
  ╠═╡ =#

# ╔═╡ d2af2a4b-8982-4e43-9fd7-0ecfdfb70511
const strict_applypatch = Ref(false)

# ╔═╡ 640663fc-06ba-491e-bd85-299514237651
begin
	function force_convert_key(::Dict{T,<:Any}, value::T) where T
		value
	end
	function force_convert_key(::Dict{T,<:Any}, value::Any) where T
		T(value)
	end
end

# ╔═╡ 48a45941-2489-4666-b4e5-88d3f82e5145
function getpath(value, path)
	if length(path) == 0
		return value
	end
	
	current, rest... = path
	if value isa AbstractDict
		key = force_convert_key(value, current)
		getpath(getindex(value, key), rest)
	else
		getpath(getproperty(value, Symbol(current)), rest)
	end
end

# ╔═╡ 752b2da3-ff24-4758-8843-186368069888
function applypatch!(value, patches::Array{JSONPatch})
	for patch in patches
		applypatch!(value, patch)
	end
	return value
end

# ╔═╡ 3e285076-1d97-4728-87cf-f71b22569e57
# ╠═╡ skip_as_script = true
#=╠═╡
md"### applypatch! AddPatch"
  ╠═╡ =#

# ╔═╡ d7ea6052-9d9f-48e3-92fb-250afd69e417
begin
    _convert(::Type{Base.UUID}, s::String) = Base.UUID(s)
    _convert(::Type{T}, a::AbstractArray) where {T<:Array} = _convert.(eltype(T), a)
    _convert(x, y) = convert(x, y)

    function _convert(::Type{<:Dict}, patch::ReplacePatch)
        Dict{String,Any}("op" => "replace", "path" => patch.path, "value" => patch.value)
    end

    function _setproperty!(x, f::Symbol, v)
        type = fieldtype(typeof(x), f)
        return setfield!(x, f, _convert(type, v))
    end
end

# ╔═╡ 7feeee3a-3aec-47ce-b8d7-74a0d9b0b381
# ╠═╡ skip_as_script = true
#=╠═╡
_convert(Dict, ReplacePatch([:x, :y], 10))
  ╠═╡ =#

# ╔═╡ dd87ca7e-2de1-11eb-2ec3-d5721c32f192
function applypatch!(value, patch::AddPatch)
	if length(patch.path) == 0
		throw("Impossible")
	else
		last = patch.path[end]
		rest = patch.path[begin:end - 1]
		subvalue = getpath(value, rest)
		if subvalue isa AbstractDict
			key = force_convert_key(subvalue, last)
			if strict_applypatch[]
				@assert get(subvalue, key, nothing) === nothing
			end
			subvalue[key] = patch.value
		else
			key = Symbol(last)
			if strict_applypatch[]
				@assert getproperty(subvalue, key) === nothing
			end
			_setproperty!(subvalue, key, patch.value)
		end
	end
	return value
end

# ╔═╡ a11e4082-4ff4-4c1b-9c74-c8fa7dcceaa6
# ╠═╡ skip_as_script = true
#=╠═╡
md"*Should throw in strict mode:*"
  ╠═╡ =#

# ╔═╡ be6b6fc4-e12a-4cef-81d8-d5115fda50b7
# ╠═╡ skip_as_script = true
#=╠═╡
md"### applypatch! ReplacePatch"
  ╠═╡ =#

# ╔═╡ 6509d62e-77b6-499c-8dab-4a608e44720a
function applypatch!(value, patch::ReplacePatch)
	if length(patch.path) == 0
		throw("Impossible")
	else
		last = patch.path[end]
		rest = patch.path[begin:end - 1]
		subvalue = getpath(value, rest)
		if subvalue isa AbstractDict
			key = force_convert_key(subvalue, last)
			if strict_applypatch[]
				@assert get(subvalue, key, nothing) !== nothing
			end
			subvalue[key] = patch.value
		else
			key = Symbol(last)
			if strict_applypatch[]
				@assert getproperty(subvalue, key) !== nothing
			end
			_setproperty!(subvalue, key, patch.value)
		end
	end
	return value
end

# ╔═╡ f1dde1bd-3fa4-48b7-91ed-b2f98680fcc1
# ╠═╡ skip_as_script = true
#=╠═╡
md"*Should throw in strict mode:*"
  ╠═╡ =#

# ╔═╡ f3ef354b-b480-4b48-8358-46dbf37e1d95
# ╠═╡ skip_as_script = true
#=╠═╡
md"### applypatch! RemovePatch"
  ╠═╡ =#

# ╔═╡ ddaf5b66-2de1-11eb-3348-b905b94a984b
function applypatch!(value, patch::RemovePatch)
	if length(patch.path) == 0
		throw("Impossible")
	else
		last = patch.path[end]
		rest = patch.path[begin:end - 1]
		subvalue = getpath(value, rest)
		if subvalue isa AbstractDict
			key = force_convert_key(subvalue, last)
			if strict_applypatch[]
				@assert get(subvalue, key, nothing) !== nothing
			end
			delete!(subvalue, key)
		else
			key = Symbol(last)
			if strict_applypatch[]
				@assert getproperty(subvalue, key) !== nothing
			end
			_setproperty!(subvalue, key, nothing)
		end
	end
	return value
end

# ╔═╡ e65d483a-4c13-49ba-bff1-1d54de78f534
#=╠═╡
let
	dict_1_copy = deepcopy(dict_1)
	applypatch!(dict_1_copy, example_patches)
end
  ╠═╡ =#

# ╔═╡ 595fdfd4-3960-4fbd-956c-509c4cf03473
#=╠═╡
@test applypatch!(deepcopy(notebook1), notebook1_to_notebook2) == notebook2
  ╠═╡ =#

# ╔═╡ c3e4738f-4568-4910-a211-6a46a9d447ee
#=╠═╡
@test applypatch!(Dict(:y => "x"), AddPatch([:x], "-")) == Dict(:y => "x", :x => "-")
  ╠═╡ =#

# ╔═╡ 0f094932-10e5-40f9-a3fc-db27a85b4999
#=╠═╡
@test applypatch!(Dict(:x => "x"), AddPatch([:x], "-")) == Dict(:x => "-")
  ╠═╡ =#

# ╔═╡ a560fdca-ee12-469c-bda5-62d7203235b8
#=╠═╡
@test applypatch!(Dict(:x => "x"), ReplacePatch([:x], "-")) == Dict(:x => "-")
  ╠═╡ =#

# ╔═╡ 01e3417e-334e-4a8d-b086-4bddc42737b3
#=╠═╡
@test applypatch!(Dict(:y => "x"), ReplacePatch([:x], "-")) == Dict(:x => "-", :y => "x")
  ╠═╡ =#

# ╔═╡ 96a80a23-7c56-4c41-b489-15bc1c4e3700
#=╠═╡
@test applypatch!(Dict(:x => "x"), RemovePatch([:x])) == Dict()
  ╠═╡ =#

# ╔═╡ df41caa7-f0fc-4b0d-ab3d-ebdab4804040
# ╠═╡ skip_as_script = true
#=╠═╡
md"*Should throw in strict mode:*"
  ╠═╡ =#

# ╔═╡ fac65755-2a2a-4a3c-b5a8-fc4f6d256754
#=╠═╡
@test applypatch!(Dict(:y => "x"), RemovePatch([:x])) == Dict(:y => "x")
  ╠═╡ =#

# ╔═╡ e55d1cea-2de1-11eb-0d0e-c95009eedc34
# ╠═╡ skip_as_script = true
#=╠═╡
md"## Testing"
  ╠═╡ =#

# ╔═╡ b05fcb88-3781-45d0-9f24-e88c339a72e5
# ╠═╡ skip_as_script = true
#=╠═╡
macro test2(expr)
	quote nothing end
end
  ╠═╡ =#

# ╔═╡ e7e8d076-2de1-11eb-0214-8160bb81370a
#=╠═╡
@test notebook1 == deepcopy(notebook1)
  ╠═╡ =#

# ╔═╡ ee70e282-36d5-4772-8585-f50b9a67ca54
# ╠═╡ skip_as_script = true
#=╠═╡
md"## Track"
  ╠═╡ =#

# ╔═╡ a3e8fe70-cbf5-4758-a0f2-d329d138728c
# ╠═╡ skip_as_script = true
#=╠═╡
function prettytime(time_ns::Number)
    suffices = ["ns", "μs", "ms", "s"]
	
	current_amount = time_ns
	suffix = ""
	for current_suffix in suffices
    	if current_amount >= 1000.0
        	current_amount = current_amount / 1000.0
		else
			suffix = current_suffix
			break
		end
	end
    
    # const roundedtime = time_ns.toFixed(time_ns >= 100.0 ? 0 : 1)
	roundedtime = if current_amount >= 100.0
		round(current_amount; digits=0)
	else
		round(current_amount; digits=1)
	end
    return "$(roundedtime) $(suffix)"
end
  ╠═╡ =#

# ╔═╡ 0e1c6442-9040-49d9-b754-173583db7ba2
# ╠═╡ skip_as_script = true
#=╠═╡
begin
    Base.@kwdef struct Tracked
		expr
		value
		time
		bytes
		times_ran = 1
		which = nothing
		code_info = nothing
    end
    function Base.show(io::IO, mime::MIME"text/html", value::Tracked)
	times_ran = if value.times_ran === 1
		""
	else
		"""<span style="opacity: 0.5"> ($(value.times_ran)×)</span>"""
	end
	# method = sprint(show, MIME("text/plain"), value.which)
	code_info = if value.code_info ≠ nothing
		codelength = length(value.code_info.first.code)
		"$(codelength) frames in @code_typed"
	else
		""
	end
	color = if value.time > 1
		"red"
	elseif value.time > 0.001
		"orange"
	elseif value.time > 0.0001
		"blue"
	else
		"green"
	end
		
	
	show(io, mime, HTML("""
		<div
			style="
				display: flex;
				flex-direction: row;
				align-items: center;
			"
		>
			<div
				style="
					width: 12px;
					height: 12px;
					border-radius: 50%;
					background-color: $(color);
				"
			></div>
			<div style="width: 12px"></div>
			<div>
				<code
					class="language-julia"
					style="
						background-color: transparent;
						filter: grayscale(1) brightness(0.8);
					"
				>$(value.expr)</code>
				<div style="
					font-family: monospace;
					font-size: 12px;
					color: $(color);
				">
					$(prettytime(value.time * 1e9 / value.times_ran))
					$(times_ran)
				</div>
				<div style="
					font-family: monospace;
					font-size: 12px;
					color: gray;
				">$(code_info)</div>

			</div>
			
		</div>
	"""))
    end
	Tracked
end
  ╠═╡ =#

# ╔═╡ 7618aef7-1884-4e32-992d-0fd988e1ab20
# ╠═╡ skip_as_script = true
#=╠═╡
macro track(expr)
	times_ran_expr = :(1)
	expr_to_show = expr
	if expr.head == :for
		@assert expr.args[1].head == :(=)
		times_ran_expr = expr.args[1].args[2]
		expr_to_show = expr.args[2].args[2]
	end

	Tracked # reference so that baby Neptune understands
				
	quote
		local times_ran = length($(esc(times_ran_expr)))
		local value, time, bytes = @timed $(esc(expr))
		
		local method = nothing
		local code_info = nothing
		try
			# Uhhh
			method = @which $(expr_to_show)
			code_info = @code_typed $(expr_to_show)
		catch nothing end
		Tracked(
			expr=$(QuoteNode(expr_to_show)),
			value=value,
			time=time,
			bytes=bytes,
			times_ran=times_ran,
			which=method,
			code_info=code_info
		)
	end
end
  ╠═╡ =#

# ╔═╡ db99e5c9-d8cd-4314-90e2-99976e81283d
#=╠═╡
@track example_patches[1] == example_patches[2]
  ╠═╡ =#

# ╔═╡ 2b342873-916c-4efb-b62c-b46a96bd6a2d
#=╠═╡
@track example_patches[2] == example_patches[2]
  ╠═╡ =#

# ╔═╡ 7b8ab89b-bf56-4ddf-b220-b4881f4a2050
#=╠═╡
@track Base.convert(JSONPatch, convert(Dict, add_patch)) == add_patch
  ╠═╡ =#

# ╔═╡ 48ccd28a-060d-4214-9a39-f4c4e506d1aa
#=╠═╡
@track Base.convert(JSONPatch, convert(Dict, remove_patch)) == remove_patch
  ╠═╡ =#

# ╔═╡ 34d86e02-dd34-4691-bb78-3023568a5d16
#=╠═╡
@track Base.convert(JSONPatch, _convert(Dict, replace_patch)) == replace_patch
  ╠═╡ =#

# ╔═╡ 95ff676d-73c8-44cb-ac35-af94418737e9
#=╠═╡
@track for _ in 1:100 diff(celldict1, celldict2) end
  ╠═╡ =#

# ╔═╡ 8c069015-d922-4c60-9340-8d65c80b1a06
#=╠═╡
@track for _ in 1:1000 diff(large_dict_1, large_dict_1) end
  ╠═╡ =#

# ╔═╡ bc9a0822-1088-4ee7-8c79-98e06fd50f11
#=╠═╡
@track for _ in 1:1000 diff(large_dict_1, large_dict_2) end
  ╠═╡ =#

# ╔═╡ ddf1090c-5239-41df-ae4d-70aeb3a75f2b
#=╠═╡
let
	old = use_triple_equals_for_arrays[]
	use_triple_equals_for_arrays[] = true
	
	result = @track for _ in 1:1000 diff(large_dict_1, large_dict_1) end
	
	use_triple_equals_for_arrays[] = old
	result
end
  ╠═╡ =#

# ╔═╡ 88009db3-f40e-4fd0-942a-c7f4a7eecb5a
#=╠═╡
let
	old = use_triple_equals_for_arrays[]
	use_triple_equals_for_arrays[] = true
	
	result = @track for _ in 1:1000 diff(large_dict_1, large_dict_2) end
	
	use_triple_equals_for_arrays[] = old
	result
end
  ╠═╡ =#

# ╔═╡ c287009f-e864-45d2-a4d0-a525c988a6e0
#=╠═╡
@track for _ in 1:1000 diff(many_items_1, many_items_1) end
  ╠═╡ =#

# ╔═╡ 67a1ae27-f7df-4f84-8809-1cc6a9bcd1ce
#=╠═╡
@track for _ in 1:1000 diff(many_items_1, many_items_2) end
  ╠═╡ =#

# ╔═╡ fa959806-3264-4dd5-9f94-ba369697689b
#=╠═╡
@track for _ in 1:1000 direct_diff(cell2, cell1) end
  ╠═╡ =#

# ╔═╡ a9088341-647c-4fe1-ab85-d7da049513ae
#=╠═╡
@track for _ in 1:1000 diff(Deep(cell1), Deep(cell2)) end
  ╠═╡ =#

# ╔═╡ 1a26eed8-670c-43bf-9726-2db84b1afdab
#=╠═╡
@track sleep(0.1)
  ╠═╡ =#

# ╔═╡ Cell order:
# ╟─d948dc6e-2de1-11eb-19e7-cb3bb66353b6
# ╟─1a6e1853-6db1-4074-bce0-5f274351cece
# ╟─49fc1f97-3b8f-4297-94e5-2e24c001d35c
# ╠═d8e73b90-24c5-4e50-830b-b1dbe6224c8e
# ╠═19646596-b35b-44fa-bfcf-891f9ffb748c
# ╠═7ca087b8-73ac-49ea-9c5a-2971f0da491f
# ╟─9d2c07d9-16a9-4b9f-a375-2adb6e5b907a
# ╠═e65d483a-4c13-49ba-bff1-1d54de78f534
# ╟─336bfd4f-8a8e-4a2d-be08-ee48d6a9f747
# ╠═db116c0a-2de1-11eb-2a56-872af797c547
# ╠═bd0d46bb-3e58-4522-bae0-83eb799196c4
# ╠═db2d8a3e-2de1-11eb-02b8-9ffbfaeff61c
# ╠═ffe9b3d9-8e35-4a31-bab2-8787a4140594
# ╠═894de8a7-2757-4d7a-a2be-1069fa872911
# ╠═9a364714-edb1-4bca-9387-a8bbacccd10d
# ╠═9321d3be-cb91-4406-9dc7-e5c38f7d377c
# ╠═73631aea-5e93-4da2-a32d-649029660d4e
# ╠═0fd3e910-abcc-4421-9d0b-5cfb90034338
# ╟─aad7ab32-eecf-4aad-883d-1c802cad6c0c
# ╠═732fd744-acdb-4507-b1de-6866ec5563dd
# ╠═17606cf6-2d0f-4245-89a3-746ad818a664
# ╠═c7ac7d27-7bf9-4209-8f3c-e4d52c543e29
# ╠═042f7788-e996-430e-886d-ffb4f70dea9e
# ╠═9d2dde5c-d404-4fbc-b8e0-5024303c8052
# ╠═f649f67c-aab0-4d35-a799-f398e5f3ecc4
# ╠═63087738-d70c-46f5-b072-21cd8953df35
# ╠═aa81974a-7254-45e0-9bfe-840c4793147f
# ╠═31188a03-76ba-40cf-a333-4d339ce37711
# ╠═7524a9e8-1a6d-4851-b50e-19415f25a84b
# ╟─db99e5c9-d8cd-4314-90e2-99976e81283d
# ╟─2b342873-916c-4efb-b62c-b46a96bd6a2d
# ╟─5ddfd616-db20-451b-bc1e-2ad52e0e2777
# ╟─24e93923-eab9-4a7b-9bc7-8d8a1209a78f
# ╟─09ddf4d9-5ccb-4530-bfab-d11b864e872a
# ╟─d9e764db-94fc-44f7-8c2e-3d63f4809617
# ╟─99df99ad-aad5-4275-97d4-d1ceeb2f8d15
# ╟─2d665639-7274-495a-ae9d-f358a8219bb7
# ╟─f658a72d-871d-49b3-9b73-7efedafbd7a6
# ╠═230bafe2-aaa7-48f0-9fd1-b53956281684
# ╟─07eeb122-6706-4544-a007-1c8d6581eec8
# ╠═b48e2c08-a94a-4247-877d-949d92dde626
# ╟─c59b30b9-f702-41f1-bb2e-1736c8cd5ede
# ╟─7feeee3a-3aec-47ce-b8d7-74a0d9b0b381
# ╠═921a130e-b028-4f91-b077-3bd79dcb6c6d
# ╟─6d67f8a5-0e0c-4b6e-a267-96b34d580946
# ╟─7b8ab89b-bf56-4ddf-b220-b4881f4a2050
# ╟─56b28842-4a67-44d7-95e7-55d457a44fb1
# ╟─48ccd28a-060d-4214-9a39-f4c4e506d1aa
# ╟─f10e31c0-1d2c-4727-aba5-dd676a10041b
# ╟─34d86e02-dd34-4691-bb78-3023568a5d16
# ╟─3a99e22d-42d6-4b2d-9381-022b41b0e852
# ╟─831d84a6-1c71-4e68-8c7c-27d9093a82c4
# ╟─2ad11c73-4691-4283-8f98-3d2a87926b99
# ╟─5513ea3b-9498-426c-98cb-7dc23d32f72e
# ╟─0c2d6da1-cad3-4c9f-93e9-922457083945
# ╟─84c87031-7733-4d1f-aa90-f8ab71506251
# ╟─8f265a33-3a2d-4508-9477-ca62e8ce3c12
# ╟─daf9ec12-2de1-11eb-3a8d-59d9c2753134
# ╠═0b50f6b2-8e85-4565-9f04-f99c913b4592
# ╠═59e94cb2-c2f9-4f6c-9562-45e8c15931af
# ╠═c9d5d81c-b0b6-4d1a-b1de-96d3b3701700
# ╠═24389a0a-c3ac-4438-9dfe-1d14cd033d25
# ╠═9cbaaec2-709c-4769-886c-ec92b12c18bc
# ╠═db75df12-2de1-11eb-0726-d1995cebd382
# ╠═dbc7f97a-2de1-11eb-362f-055a734d1a9e
# ╠═67ade214-2de3-11eb-291d-135a397d629b
# ╠═b8c58aa4-c24d-48a3-b2a8-7c01d50a3349
# ╠═5ab390f9-3b0c-4978-9e21-2aaa61db2ce4
# ╠═09f53db0-21ae-490b-86b5-414eba403d57
# ╟─59b46bfe-da74-43af-9c11-cb0bdb2c13a2
# ╟─200516da-8cfb-42fe-a6b9-cb4730168923
# ╟─76326e6c-b95a-4b2d-a78c-e283e5fadbe2
# ╟─95ff676d-73c8-44cb-ac35-af94418737e9
# ╠═664cd334-91c7-40dd-a2bf-0da720307cfc
# ╠═b7fa5625-6178-4da8-a889-cd4f014f43ba
# ╠═dbdd1df0-2de1-11eb-152f-8d1af1ad02fe
# ╠═595fdfd4-3960-4fbd-956c-509c4cf03473
# ╟─3924953f-787a-4912-b6ee-9c9d3030f0f0
# ╠═80689881-1b7e-49b2-af97-9e3ab639d006
# ╠═fd22b6af-5fd2-428a-8291-53e223ea692c
# ╠═bcd5059b-b0d2-49d8-a756-92349aa56aca
# ╠═e7fd6bab-c114-4f3e-b9ad-1af2d1147770
# ╟─43c36ab7-e9ac-450a-8abe-435412f2be1d
# ╟─2983f6d4-c1ca-4b66-a2d3-f858b0df2b4c
# ╟─fdc427f0-dfe8-4114-beca-48fc15434534
# ╟─8c069015-d922-4c60-9340-8d65c80b1a06
# ╟─bc9a0822-1088-4ee7-8c79-98e06fd50f11
# ╟─1cf22fe6-4b58-4220-87a1-d7a18410b4e8
# ╟─ddf1090c-5239-41df-ae4d-70aeb3a75f2b
# ╟─88009db3-f40e-4fd0-942a-c7f4a7eecb5a
# ╟─ffb01ab4-e2e3-4fa4-8c0b-093d2899a536
# ╠═8188de75-ae6e-48aa-9495-111fd27ffd26
# ╠═d807195e-ba27-4015-92a7-c9294d458d47
# ╠═2e91a1a2-469c-4123-a0d7-3dcc49715738
# ╟─61b81430-d26e-493c-96da-b6818e58c882
# ╠═b8061c1b-dd03-4cd1-b275-90359ae2bb39
# ╠═aeab3363-08ba-47c2-bd33-04a004ed72c4
# ╟─62de3e79-4b4e-41df-8020-769c3c255c3e
# ╟─c287009f-e864-45d2-a4d0-a525c988a6e0
# ╟─67a1ae27-f7df-4f84-8809-1cc6a9bcd1ce
# ╟─c7de406d-ccfe-41cf-8388-6bd2d7c42d64
# ╠═b9cc11ae-394b-44b9-bfbe-541d7720ead0
# ╠═c3c675be-9178-4176-afe0-30501786b72c
# ╠═02585c72-1d92-4526-98c2-1ca07aad87a3
# ╟─2d084dd1-240d-4443-a8a2-82ae6e0b8900
# ╟─3e05200f-071a-4ebe-b685-ff980f07cde7
# ╟─fa959806-3264-4dd5-9f94-ba369697689b
# ╟─a9088341-647c-4fe1-ab85-d7da049513ae
# ╟─dd312598-2de1-11eb-144c-f92ed6484f5d
# ╠═d2af2a4b-8982-4e43-9fd7-0ecfdfb70511
# ╠═640663fc-06ba-491e-bd85-299514237651
# ╠═48a45941-2489-4666-b4e5-88d3f82e5145
# ╠═752b2da3-ff24-4758-8843-186368069888
# ╟─3e285076-1d97-4728-87cf-f71b22569e57
# ╠═d7ea6052-9d9f-48e3-92fb-250afd69e417
# ╠═dd87ca7e-2de1-11eb-2ec3-d5721c32f192
# ╟─c3e4738f-4568-4910-a211-6a46a9d447ee
# ╟─a11e4082-4ff4-4c1b-9c74-c8fa7dcceaa6
# ╟─0f094932-10e5-40f9-a3fc-db27a85b4999
# ╟─be6b6fc4-e12a-4cef-81d8-d5115fda50b7
# ╠═6509d62e-77b6-499c-8dab-4a608e44720a
# ╟─a560fdca-ee12-469c-bda5-62d7203235b8
# ╟─f1dde1bd-3fa4-48b7-91ed-b2f98680fcc1
# ╟─01e3417e-334e-4a8d-b086-4bddc42737b3
# ╟─f3ef354b-b480-4b48-8358-46dbf37e1d95
# ╠═ddaf5b66-2de1-11eb-3348-b905b94a984b
# ╟─96a80a23-7c56-4c41-b489-15bc1c4e3700
# ╟─df41caa7-f0fc-4b0d-ab3d-ebdab4804040
# ╟─fac65755-2a2a-4a3c-b5a8-fc4f6d256754
# ╟─e55d1cea-2de1-11eb-0d0e-c95009eedc34
# ╠═3e07f976-6cd0-4841-9762-d40337bb0645
# ╠═e748600a-2de1-11eb-24be-d5f0ecab8fa4
# ╠═b05fcb88-3781-45d0-9f24-e88c339a72e5
# ╠═e7e8d076-2de1-11eb-0214-8160bb81370a
# ╟─ee70e282-36d5-4772-8585-f50b9a67ca54
# ╟─1a26eed8-670c-43bf-9726-2db84b1afdab
# ╟─0e1c6442-9040-49d9-b754-173583db7ba2
# ╟─7618aef7-1884-4e32-992d-0fd988e1ab20
# ╟─a3e8fe70-cbf5-4758-a0f2-d329d138728c
