# ReadableNumbers.jl


 ```ruby
 `
     Extended precision floating point values are made more easily readable.
     
                      Copyright © 2016 by Jeffrey Sarnoff    
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

