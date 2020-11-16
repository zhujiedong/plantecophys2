### Citation

this is a revised version of Duursma, 2015:

> Duursma, R.A., 2015. Plantecophys - An R Package for Analysing and Modelling Leaf Gas Exchange Data. PLoS ONE 10, e0143346. [doi:10.1371/journal.pone.0143346]().

the main purpose of the `planecophys2` is to revise the `plantecophys` for LI-6800.

1. revise the varname for LI-6800

2. Use TleafCond for Tleaf according to the LI-6800 user's manual

3. print the summary(nlsfit) directly to check the results of nonlinear fittings

4. some small changes for the plot method

this is very beginning version, it is the same with `plantecophys` except the above small changes. As the LI-6400 is end of life, and the LI-6800 has more advanced functions like RACiR, it is necessay to fit the Aci curve and RACiR with less typing.


