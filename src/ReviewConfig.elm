module ReviewConfig exposing (config)

import NoAlways
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDuplicatePorts
import NoExposingEverything
import NoForbiddenWords
import NoImportingEverything
import NoMissingTypeAnnotation
import NoUnsafePorts
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Variables
import NoUnusedPorts
import Review.Rule as Rule exposing (Rule)
import UseCamelCase
import Vendor.NoBooleanCase as NoBooleanCase
import Vendor.NoFullyAppliedPrefixOperator as NoFullyAppliedPrefixOperator
import Vendor.NoLeftPizza as NoLeftPizza
import Vendor.NoListLiteralsConcat as NoListLiteralsConcat
import Vendor.NoRedundantConcat as NoRedundantConcat
import Vendor.NoRedundantCons as NoRedundantCons


config : List Rule
config =
    [ NoAlways.rule
    , NoBooleanCase.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoDuplicatePorts.rule
    , NoExposingEverything.rule
    , NoForbiddenWords.rule
        [ "- [ ]"
        , "TODO"
        ]
    , NoFullyAppliedPrefixOperator.rule
    , NoImportingEverything.rule []
    , NoLeftPizza.rule
        |> Rule.ignoreErrorsForDirectories
            [ -- Test functions are traditionally built up using a left pizza.
              -- While we don't want them in our regular code, let's allow them
              -- just for tests.
              "tests/"
            ]
    , NoListLiteralsConcat.rule
    , NoMissingTypeAnnotation.rule
    , NoRedundantConcat.rule
    , NoRedundantCons.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnused.Variables.rule
    , NoUnusedPorts.rule
    , UseCamelCase.rule UseCamelCase.default
    ]
        |> List.map
            (Rule.ignoreErrorsForFiles
                [ "src/Html/Tailwind.elm"
                , "src/Svg/Tailwind.elm"
                ]
            )
