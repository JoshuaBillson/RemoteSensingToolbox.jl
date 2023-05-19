using Rasters, Statistics, DataFrames, RSToolbox, Shapefile

function main()
    # Read Landsat
    landsat = Landsat8("../../HyperspectralReconstruction/data/Landsat/2020-08-02/LC08_L2SP_043024_20200802_20200914_02_T1/")

    # Convert DN to Surface Reflectance
    landsat_sr = dn_to_reflectance(landsat)

    # Load Shapefile
    shp = Shapefile.Table("/Users/jmbillson/HyperspectralReconstruction/data/shapefiles/landcover/landcover.shp") |> DataFrame

    sigs = extract_signatures(landsat_sr.stack, shp, :cover)
    plot_signatures(sigs, "sig1.png")
end

# main()