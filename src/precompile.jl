using PrecompileTools: PrecompileTools

PrecompileTools.@compile_workload begin
    nb = Neptune.Notebook([
        Neptune.Cell("""md"Hello *world*" """)
        Neptune.Cell("""[f(x)]""")
        Neptune.Cell("""x = 1""")
        Neptune.Cell(
            """
            function f(z::Integer)
                z / 123
            end
            """)
        Neptune.Cell(
            """
            "asdf"
            begin
                while false
                    local p = 123
                    try
                        [(x,a...) for x in (a for a in b)]
                        A.B.hello() do z
                            @gensym z
                            (z) -> z/:(z / z)
                        end
                    catch
                    end
                end
            end
            """
        )
    ])
    let
        topology = Neptune.updated_topology(nb.topology, nb, nb.cells)
        # Our reactive sorting algorithm.
        Neptune.topological_order(topology, topology.cell_order)
    end

    # let
    #     io = IOBuffer()
    #     # Notebook file format.
    #     Neptune.save_notebook(io, nb)
    #     seekstart(io)
    #     Neptune.load_notebook_nobackup(io, "whatever.jl")
    # end

    let
        state1 = Neptune.notebook_to_js(nb)
        state2 = Neptune.notebook_to_js(nb)
        # MsgPack
        Neptune.unpack(Neptune.pack(state1))
        # State diffing
        Neptune.Firebasey.diff(state1, state2)
    end

    s = Neptune.ServerSession(;
        options=Neptune.Configuration.from_flat_kwargs(
            disable_writing_notebook_files=true,
            workspace_use_distributed=false,
            auto_reload_from_file=false,
            run_notebook_on_load=false,
            lazy_workspace_creation=true,
            capture_stdout=false,
        )
    )
    
    finalize(s)
end

using PrecompileSignatures: @precompile_signatures
@precompile_signatures(Neptune)
