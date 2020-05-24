module ReviewConfig exposing (config)

import NoAlways
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDuplicatePorts
import NoExposingEverything
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


config : List Rule
config =
    [ NoAlways.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoDuplicatePorts.rule
    , NoExposingEverything.rule
    , NoImportingEverything.rule []
    , NoMissingTypeAnnotation.rule
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
