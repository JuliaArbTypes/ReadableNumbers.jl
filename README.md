# ReadableNumbers.jl

### Extended precision floating point values are made more easily readable.
     
##### Copyright © 2016 by Jeffrey Sarnoff.  Released under the MIT license.
`
 ```

-------

### installation
Pkg.clone("https://github.com/JuliaArbTypes/ReadableNumbers.jl")

### use
```julia
using ReadableNumbers

golden_str = readable_str(golden)

readable(golden,3,4,' ','_')

```

