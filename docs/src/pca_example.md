```@meta
CurrentModule = RemoteSensingToolbox
```

# Principal Component Analysis

Remotely sensed imagery typically consists of anywhere from five to several hundred spectral bands. These bands are often highly correlated because they occupy similar spectral regions. 

PCA is used in remote sensing to:
- Create a smaller dataset from multiple bands, while retaining as much of the original spectral information as possible. The new image will consist of several uncorrelated PC bands.
- Reveal complex relationships among spectral features.
- Determine which characteristics are prevalent in most of the bands, and those that are specific to only a few.

Our first step is to load and visualize our initial image.

```julia
using RemoteSensingToolbox, Rasters
using Pipe: @pipe

sentinel = read_bands(Sentinel2, "data/T11UPT_20200804T183919/R60m/")
roi = @view sentinel[Rasters.X(900:1799), Rasters.Y(1:900)]
visualize(roi, TrueColor{Sentinel2}; upper=0.99)
```

![](figures/original.png)

Next, we'll fit a PCA transformation to our image. The reason that we make fitting and transformation seperate is so that the procedure can be repeated and reversed. We'll try keeping all of the components at first so we can get a sense of how many we'll need to retain. 

```julia
pca_full = fit_transform(PCA, sentinel, method=:cov)
```
```
PCA(in_dim=11, out_dim=11, explained_variance=1.0)

Projection Matrix:
11×11 Matrix{Float64}:
 -0.026   -0.2068  -0.359    0.312   -0.0955  -0.4791   0.2245  -0.6117   0.1862  -0.1494   0.1005
 -0.0361  -0.2354  -0.3739   0.1417  -0.0495  -0.1544   0.3841   0.3908  -0.3467   0.2438  -0.5265
 -0.0775  -0.2406  -0.3554  -0.1492   0.0607   0.0575   0.0611   0.2326  -0.4335  -0.2812   0.6751
 -0.0396  -0.3231  -0.321   -0.0301  -0.048    0.4006   0.1103   0.1691   0.6681   0.3318   0.1738
 -0.1194  -0.2914  -0.2233  -0.3824   0.3987   0.3538  -0.1552  -0.388   -0.0944  -0.2647  -0.4087
 -0.3925   0.0354  -0.0791  -0.5717   0.1024  -0.5641  -0.2124   0.0649   0.1101   0.3449   0.0496
 -0.4949   0.1513  -0.0179  -0.1062  -0.4124   0.0178   0.1554   0.231    0.257   -0.6108  -0.1833
 -0.5257   0.084   -0.0977   0.6026   0.4321   0.0232  -0.3684   0.1418   0.0193   0.0173   0.0145
 -0.155   -0.549    0.63     0.0248   0.3084  -0.1466   0.361    0.095    0.0889  -0.0983   0.0592
 -0.0695  -0.5511   0.1381   0.1059  -0.5562   0.0011  -0.5628  -0.0342  -0.1565   0.0709  -0.0666
 -0.5216   0.1354   0.1415  -0.0111  -0.2273   0.3423   0.3317  -0.3898  -0.3017   0.39     0.1247

Importance of Components:
  Cumulative Variance: 0.76  0.9679  0.989  0.9938  0.9968  0.9984  0.9991  0.9995  0.9998  0.9999  1.0
  Explained Variance: 0.76  0.2078  0.0212  0.0047  0.0031  0.0016  0.0007  0.0004  0.0002  0.0002  0.0001
```

If we look at the cumulative variance, we see that we only need to retain three principal components to account for 98.9% of the variance in our data. Knowing this, let's try again with only three components.

```julia
pca = fit_transform(PCA, sentinel, components=3)
```
```
PCA(in_dim=11, out_dim=3, explained_variance=0.989)

Projection Matrix:
11×3 Matrix{Float64}:
 -0.026   -0.2068  -0.359
 -0.0361  -0.2354  -0.3739
 -0.0775  -0.2406  -0.3554
 -0.0396  -0.3231  -0.321
 -0.1194  -0.2914  -0.2233
 -0.3925   0.0354  -0.0791
 -0.4949   0.1513  -0.0179
 -0.5257   0.084   -0.0977
 -0.155   -0.549    0.63
 -0.0695  -0.5511   0.1381
 -0.5216   0.1354   0.1415

Importance of Components:
  Cumulative Variance: 0.76  0.9679  0.989
  Explained Variance: 0.76  0.2078  0.0212
```

Now we can perform the learned PCA transformation on our image and visualize the results.

```julia
transformed = transform(pca, roi)
r, g, b = [view(transformed, Rasters.Band(i)) for i in 1:3]
visualize(r, g, b; upper=0.99)
```

![](figures/pca.png)

Each band in the transformed image corresponds to a linear combination of multiple bands from the original image. Thus, the bands no longer relate to wavelengths of light, but instead capture different features from the underlying spectral signatures. In the above image, we can see that water is highlighted in yellow, vegetation is green, and built-up land produces hues of bright red. Thus, we have managed to retain the majority of spectral information while reducing the number of bands from 11 to 3.

We may also wish to reverse the transformation in order to recover an approximation of the original image. We can do this with the `inverse_transform` method, which will return a `RasterStack` with the same layers as the original image, assuming that it was itself a `RasterStack`. This makes the recovered image compatible with methods that dispatch on `AbstractBandset` types, such as `visualize`.

```julia
recovered = inverse_transform(pca, transformed)
visualize(recovered, TrueColor{Sentinel2}; upper=0.99)
```

![](figures/recovered.png)

We can see that the color of the recovered image is indeed similar, but not identical to that of the original. Had we elected to retain all 11 components, we would find the two to be identical (minus some floating point error).