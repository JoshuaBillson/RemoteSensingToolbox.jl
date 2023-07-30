using RemoteSensingToolbox, DataFrames, Shapefile, CairoMakie
using Pipe: @pipe

function main()
    # Read Landsat And Convert DNs To Reflectance
    landsat = @pipe Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance(Landsat8, _)

    # Load Shapefile
    shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

    # Plot Signatures
    fig1 = plot_signatures(landsat, shp, :C_name)
    CairoMakie.save("landsat_sigs_wong.png", fig1)

    # Plot Signatures With Custom Colors
    fig2 = plot_signatures(landsat, shp, :C_name; colors=cgrad(:tab10))
    CairoMakie.save("landsat_sigs_tab10.png", fig2)

    # Plot Metaclasses
    colors = cgrad([:orange, :green, :saddlebrown, :navy], 4, categorical=true)
    fig3 = plot_signatures(landsat, shp, :MC_name; colors=colors)
    CairoMakie.save("landsat_sigs_metaclass.png", fig3)

    # Load Sentinel and DESIS
    sentinel = @pipe Sentinel2A("data/T11UPT_20200804T183919/") |> dn_to_reflectance(Sentinel2, _)
    desis = DESIS("data/DESIS-HSI-L2A-DT0483531728_001-20200804T234520-V0210/SPECTRAL_IMAGE.tif") |> dn_to_reflectance(DESIS, _)
    sensors = [landsat, sentinel, desis]

    # Create Figure
    fig4 = Figure(resolution=(1000, 800))
    
    # Create Axes
    ax1 = Axis(fig4[1,1], xticksvisible=false, xticklabelsvisible=false)
    ax2 = Axis(fig4[2,1], ylabel="Reflectance", ylabelfont=:bold, xticksvisible=false, xticklabelsvisible=false)
    ax3 = Axis(fig4[3,1], xlabel="Wavelength (nm)", xlabelfont=:bold)
    axs = [ax1, ax2, ax3]

    # Plot Signatures
    for (sensor, ax) in zip(sensors, axs)
        plot_signatures!(ax, sensor, shp, :MC_name; colors=colors)
        xlims!(ax, 400, 1000)
    end

    # Add Legend
    Legend(fig4[1:3,2], first(axs), "Classification")

    # Save Figure
    CairoMakie.save("multisensor_sigs.png", fig4)
end

main()