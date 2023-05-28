using RemoteSensingToolbox, Rasters, Images
using Pipe: @pipe

function main()
    # Read Landsat
    landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/")

    # Convert DNs to Reflectance
    landsat_sr = dn_to_reflectance(landsat)

    # Crop A Region of Interest
    roi = @view landsat_sr[X(5801:6800), Y(2201:3200)]

    # Create Tiles
    tiles = create_tiles(roi, (500, 500))
    overlapping_tiles = create_tiles(roi, (500, 500); stride=(250, 250))

    # Visualize Tiles
    @pipe tiles |>
    visualize.(_, TrueColor; upper=0.998) |> 
    mosaicview(_, ncol=2, rowmajor=true, npad=5, fillvalue=1.0) |>
    Images.save("landsat_tiles.png", _)

    # Visualize Overlapping Tiles
    @pipe overlapping_tiles |>
    visualize.(_, TrueColor; upper=0.998) |> 
    mosaicview(_, ncol=3, rowmajor=true, npad=5, fillvalue=1.0) |>
    Images.save("landsat_overlapping_tiles.png", _)

    # Create Cubes
    cubes = map(x -> tocube(x; layers=[:B2, :B3, :B4, :B5]), tiles)
    
    # Save Cubes To Disk
    for (i, cube) in enumerate(cubes)
        Rasters.write("tile_$i.tif", cube)
    end
end