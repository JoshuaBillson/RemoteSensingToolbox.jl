module Utils

using Rasters
using DocStringExtensions
using DataFrames
using Pipe: @pipe

include("skipmissing.jl")

"""
    stack2df(rs::RasterStack; dropmissingvals=true)

Convert a `RasterStack` into a `DataFrame`.

# Parameters
- `rs`: The `RasterStack` or `AbstractSensor` from which to extract spectral signatures.
- `dropmissingvals`: Whether or not to drop missing values from the `DataFrame`. If `true`, drops points with missing values in at least one layer.

# Returns
A `DataFrame` consisting of rows for each point in the `RasterStack` and columns for each layer.

# Example
```julia-repl
julia> landsat = Landsat8("data/LC08_L2SP_043024_20200802_20200914_02_T1/");

julia> stack2df(landsat.stack)
40483825×7 DataFrame
      Row │ B1      B2      B3      B4      B5      B6      B7     
          │ UInt16  UInt16  UInt16  UInt16  UInt16  UInt16  UInt16 
──────────┼────────────────────────────────────────────────────────
        1 │   8348    8345    8798    8216   14454   11201    9070
        2 │   7990    8064    8707    8106   15583   11652    9376
        3 │   8180    8247    8858    8135   17552   12097    9386
        4 │   8400    8362    8952    8262   17836   12772    9797
        5 │   8447    8398    9088    8284   20507   12857    9901
        6 │   8375    8337    8818    8190   16348   12237    9662
        7 │   7742    8005    8915    8257   16683   12465    9862
        8 │   7996    8152    9002    8530   16328   13528   10526
        9 │   8178    8213    8887    8513   17244   13059   10282
    ⋮     │   ⋮       ⋮       ⋮       ⋮       ⋮       ⋮       ⋮
 40483818 │   8609    8835    9707    9924   16742   16214   12380
 40483819 │   8520    8662    9578    9722   16355   15326   11816
 40483820 │   8484    8646    9539    9517   16800   15304   11735
 40483821 │   8645    8854    9775   10064   16739   16707   12667
 40483822 │   8454    8596    9515    9455   17095   15065   11488
 40483823 │   8586    8863    9867   10164   16688   16382   12640
 40483824 │   8601    8823    9684   10050   16210   16211   12439
 40483825 │   8700    8934    9898   10324   16947   16727   12722
                                              40483808 rows omitted
```
"""
function stack2df(rs::RasterStack; dropmissingvals=true)
    # Use Tables.jl Interface To Read RasterStack Pixels Into a DataFrame
    df = rs |> Rasters.replace_missing |> DataFrame

    # Drop Missing Values
    if dropmissingvals
        @view(df[:, Not([:X, :Y])]) |> dropmissing
    else
        return df[:,Not([:X,:Y])]
    end
end

export stack2df, RasterStackIterator

end