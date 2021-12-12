Recoverable Minimum Spanning Tree Problem
=========================================

Introduction
------------
This package provides an implementation of _recoverable minimum spanning tree problem_ in polynomial time in Julia language

Dependencies
------------

rec_st_lp.jl
----------
`model.jl` file contains a model for solving the minimum spanning tree problem written in
[JuMP](http://www.juliaopt.org/notebooks/Shuvomoy%20-%20Getting%20started%20with%20JuMP.html]) modelling language.

To be able to run this model you need `JuMP` and `GLPKMathProgInterface` Julia packages to be installed first.

Usage
-----
In order to run comparison tests load `rec_st_lp.jl` file:
```
julia> include("model.jl")
```
