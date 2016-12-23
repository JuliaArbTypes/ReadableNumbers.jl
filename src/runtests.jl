using ReadableNumbers
using Base.Test

setprecision(BigFloat,128);

@test readable(BigFloat(pi)) == "3.14159_26535_89793_23846_26433_83279_50288_4195"
@test readable(factorial(BigInt(34))) == "295,232,799,039,604,140,847,618,609,643,520,000,000"
