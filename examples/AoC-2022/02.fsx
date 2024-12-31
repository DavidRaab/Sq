#!/usr/bin/env -S dotnet fsi

// https://adventofcode.com/2022/day/2

open System.Text.RegularExpressions

type Tool =
    | Rock
    | Paper
    | Scissors

type Round = Round of Tool * Tool
type Plan  = Plan  of Round list

let inputMapping = Map [
    "A", Rock
    "B", Paper
    "C", Scissors
    "X", Rock
    "Y", Paper
    "Z", Scissors
]

let toolPoints = Map [
    Rock,     1
    Paper,    2
    Scissors, 3
]

let winningPoints = Map [
    Rock, Map [
        Rock,     3
        Paper,    6
        Scissors, 0
    ]
    Paper, Map [
        Rock,     0
        Paper,    3
        Scissors, 6
    ]
    Scissors, Map [
        Rock,     6
        Paper,    0
        Scissors, 3
    ]
]

module Plan =
    let points (Plan rounds) =
        rounds
        |> List.map (fun (Round (other,me)) ->
            toolPoints.[me] + winningPoints.[other].[me]
        )
        |> List.sum

// So annoying ... TOO Verbose
let xms =
    RegexOptions.IgnorePatternWhitespace
    ||| RegexOptions.Multiline
    ||| RegexOptions.Singleline

// Helper to fetch Regex Match
let get (x:int) (m:Match) =
    m.Groups.[x].Value


// Input data simulated as line of strings
let data = [
    "A Y"
    "B X"
    "C Z"
]

// Parse Input as a Plan
let plan = Plan [
    for line in data do
        let m = Regex.Match(line, @"\A ([ABC]) \s+ ([XYZ]) \Z", xms)
        if m.Success then
            yield Round (
                Map.find (get 1 m) inputMapping,
                Map.find (get 2 m) inputMapping
            )
]

// Looks like:
// Plan [
//   Round (Rock, Paper)
//   Round (Paper, Rock)
//   Round (Scissors, Scissors)
// ]

printfn "Plan: %A" plan
printfn "Total Points: %d" (Plan.points plan)