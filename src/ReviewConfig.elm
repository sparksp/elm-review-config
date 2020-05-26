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
import Vendor.NoMissingSubscriptionsCall as NoMissingSubscriptionsCall
import Vendor.NoRecursiveUpdate as NoRecursiveUpdate
import Vendor.NoRedundantConcat as NoRedundantConcat
import Vendor.NoRedundantCons as NoRedundantCons
import Vendor.NoUnused.Parameters as NoUnusedParameters
import Vendor.NoUnused.Patterns as NoUnusedPatterns
import Vendor.NoUselessSubscriptions as NoUselessSubscriptions


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
    , NoMissingSubscriptionsCall.rule
    , NoMissingTypeAnnotation.rule
    , NoRecursiveUpdate.rule
    , NoRedundantConcat.rule
    , NoRedundantCons.rule
    , NoUnsafePorts.rule NoUnsafePorts.any
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnusedParameters.rule
    , NoUnusedPatterns.rule
    , NoUnusedPorts.rule
    , NoUnused.Variables.rule
    , NoUselessSubscriptions.rule
    , UseCamelCase.rule UseCamelCase.default
    ]
        |> List.map
            (Rule.ignoreErrorsForFiles
                [ "src/Html/Tailwind.elm"
                , "src/Svg/Tailwind.elm"
                ]
            )
