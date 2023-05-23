using RemoteSensingToolbox, DataFrames, Shapefile

function main()
    # Read Landsat And Convert DNs To Reflectance
    landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/") |> dn_to_reflectance

    # Load Shapefile
    shp = Shapefile.Table("data/landcover/landcover.shp") |> DataFrame

    # Plot Signatures
    plot_signatures(landsat, shp, :cover, "landsat_sigs.png")
end

main()