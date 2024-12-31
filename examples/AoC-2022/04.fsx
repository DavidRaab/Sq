#!/usr/bin/env -S dotnet fsi

// https://adventofcode.com/2022/day/4

open System.Text.RegularExpressions

let data = [
    "2-4,6-8"
    "2-3,4-5"
    "5-7,7-9"
    "2-8,3-7"
    "6-6,4-6"
    "2-6,4-8"
    "11-20,15-18"
    "10-20,1-40"
]

for line in data do
    let m =
        Regex.Match(
            line,
            @"\A (\d+) - (\d+) , (\d+) - (\d+) \z",
            RegexOptions.IgnorePatternWhitespace
        )
    if m.Success then
        let get (x:int) = int m.Groups.[x].Value
        let v1,v2,v3,v4 = get 1, get 2, get 3, get 4

        if v1 >= v3 && v2 <= v4 then
            printfn "First is contained in Second: %s" line
        if v3 >= v1 && v4 <= v2 then
            printfn "Second is contained in First: %s" line
