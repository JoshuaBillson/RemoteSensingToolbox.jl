using RemoteSensingToolbox, DataFrames, Shapefile, CairoMakie
using Pipe: @pipe

function main()
    # Read Landsat And Convert DNs To Reflectance
    landsat = @pipe read_bands(Landsat8, "data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

    # Load Shapefile
    shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

    # Extract Signatures
    landsat_sigs = extract_signatures(landsat, shp, :C_name) |> summarize_signatures

    # Plot Signatures
    fig1 = plot_signatures(Landsat8, landsat_sigs)
    CairoMakie.save("landsat_sigs_wong.png", fig1)

    # Plot Signatures With Custom Colors
    fig2 = plot_signatures(Landsat8, landsat_sigs; colors=cgrad(:tab10))
    CairoMakie.save("landsat_sigs_tab10.png", fig2)

    # Load Sentinel and DESIS
    sentinel = @pipe read_bands(Sentinel2, "data/T11UPT_20200804T183919/R60m/") |> dn_to_reflectance(Sentinel2, _)
    desis = @pipe read_bands(DESIS, "data/DESIS-HSI-L2A-DT0884573241_001-20200601T234520-V0210") |> dn_to_reflectance(DESIS, _)
    sensors = [landsat, sentinel, desis]

    # Create Figure
    fig3 = Figure(resolution=(1000, 800))
    
    # Create Axes
    ax1 = Axis(fig3[1,1], title="Landsat 8", xticksvisible=false, xticklabelsvisible=false)
    ax2 = Axis(fig3[2,1], title="Sentinel 2", ylabel="Reflectance", ylabelfont=:bold, xticksvisible=false, xticklabelsvisible=false)
    ax3 = Axis(fig3[3,1], title="DESIS", xlabel="Wavelength (nm)", xlabelfont=:bold)
    axs = [ax1, ax2, ax3]

    # Plot Signatures
    colors = cgrad([:saddlebrown, :orange, :navy, :green], 4, categorical=true)
    for (bandset, sensor, ax) in zip((Landsat8, Sentinel2, DESIS), sensors, axs)
        @pipe extract_signatures(sensor, shp, :C_name) |> summarize_signatures |> plot_signatures!(ax, bandset, _)
        xlims!(ax, 400, 1000)
    end

    # Add Legend
    Legend(fig3[1:3,2], first(axs), "Classification")

    # Save Figure
    CairoMakie.save("multisensor_sigs.png", fig3)
end

#main()