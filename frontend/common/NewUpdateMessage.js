export const new_update_message = (client) =>
    fetch_pluto_releases()
        .then((releases) => {
            const local = client.version_info.pluto
            const latest = releases[releases.length - 1].tag_name
            console.log(`Neptune version ${local}`)
            const local_index = releases.findIndex((r) => r.tag_name === local)
            if (local_index !== -1) {
                const updates = releases.slice(local_index + 1)
                const recommended_updates = updates.filter((r) => r.body.toLowerCase().includes("recommended update"))
                if (recommended_updates.length > 0) {
                    console.log(`Newer version ${latest} is available`)
                    if (!client.version_info.dismiss_update_notification) {
                        alert(
                            "A new version of Neptune.jl is available! 🎉\n\n    You have " +
                                local +
                                ", the latest is " +
                                latest +
                                '.\n\nYou can update Neptune.jl using the julia package manager:\n    import Pkg; Pkg.update("Neptune")\nAfterwards, exit Neptune.jl and restart julia.'
                        )
                    }
                }
            }
        })
        .catch(() => {
            // Having this as a uncaught promise broke the frontend tests for me
            // so I'm just swallowing the error explicitly - DRAL
        })

const fetch_pluto_releases = async () => {
    let response = await fetch("https://api.github.com/repos/JuliaPluto/Neptune.jl/releases", {
        method: "GET",
        mode: "cors",
        cache: "no-cache",
        headers: {
            "Content-Type": "application/json",
        },
        redirect: "follow",
        referrerPolicy: "no-referrer",
    })
    return (await response.json()).reverse()
}
