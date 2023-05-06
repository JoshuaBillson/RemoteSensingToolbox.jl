using RSToolbox
using Documenter

DocMeta.setdocmeta!(RSToolbox, :DocTestSetup, :(using RSToolbox); recursive=true)

makedocs(;
    modules=[RSToolbox],
    authors="Joshua Billson",
    repo="https://github.com/JoshuaBillson/RSToolbox.jl/blob/{commit}{path}#{line}",
    sitename="RSToolbox.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JoshuaBillson.github.io/RSToolbox.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JoshuaBillson/RSToolbox.jl",
    devbranch="main",
)
