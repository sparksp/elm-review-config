module ReviewConfig exposing (config)

import Docs.NoMissing
import Docs.ReviewAtDocs
import Docs.ReviewLinksAndSections
import Docs.UpToDateReadmeLinks
import NoAlways
import NoDebug.Log
import NoDebug.TodoOrToString
import NoDuplicatePorts
import NoExposingEverything
import NoForbiddenWords
import NoImportingEverything
import NoInconsistentAliases
import NoMissingSubscriptionsCall
import NoMissingTypeAnnotation
import NoMissingTypeAnnotationInLetIn
import NoMissingTypeExpose
import NoModuleOnExposedNames
import NoRecordAliasConstructor
import NoRecursiveUpdate
import NoUnmatchedUnit
import NoUnoptimizedRecursion
import NoUnsafePorts
import NoUnused.CustomTypeConstructorArgs
import NoUnused.CustomTypeConstructors
import NoUnused.Dependencies
import NoUnused.Exports
import NoUnused.Modules
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import NoUnusedPorts
import NoUselessSubscriptions
import Review.Rule as Rule exposing (Rule)
import ReviewPipelineStyles
import ReviewPipelineStyles.Custom exposing (noSinglePiplinesWithSimpleInputs)
import ReviewPipelineStyles.Premade
    exposing
        ( noMultilineLeftPizza
        , noPipelinesWithConfusingNonCommutativeFunctions
        , noRepeatedParentheticalApplication
        , noSemanticallyInfixFunctionsInLeftPipelines
        , noSingleLineRightPizza
        )
import Simplify
import UseCamelCase


config : List Rule
config =
    [ Docs.NoMissing.rule
        { document = Docs.NoMissing.onlyExposed
        , from = Docs.NoMissing.exposedModules
        }
    , Docs.ReviewLinksAndSections.rule
    , Docs.ReviewAtDocs.rule
    , Docs.UpToDateReadmeLinks.rule
    , NoAlways.rule
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
        |> Rule.ignoreErrorsForDirectories
            [ -- Debug.toString is sometimes used in test failure messages.
              "tests/"
            ]
    , NoDuplicatePorts.rule
    , NoExposingEverything.rule
    , NoForbiddenWords.rule
        [ "- [ ]"
        , "REPLACEME"
        , "TODO"
        ]
    , NoImportingEverything.rule []
    , NoInconsistentAliases.config
        [ ( "Html.Attributes", "Attr" )
        , ( "Json.Decode", "Decode" )
        , ( "Json.Encode", "Encode" )
        ]
        |> NoInconsistentAliases.noMissingAliases
        |> NoInconsistentAliases.rule
    , NoMissingSubscriptionsCall.rule
    , NoMissingTypeAnnotation.rule
    , NoMissingTypeAnnotationInLetIn.rule
    , NoMissingTypeExpose.rule
    , NoModuleOnExposedNames.rule
    , NoRecordAliasConstructor.rule
    , NoRecursiveUpdate.rule
    , NoUnmatchedUnit.rule
    , NoUnoptimizedRecursion.rule (NoUnoptimizedRecursion.optOutWithComment "IGNORE TCO")
    , NoUnsafePorts.rule NoUnsafePorts.any
    , NoUnused.CustomTypeConstructors.rule []
    , NoUnused.CustomTypeConstructorArgs.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Exports.rule
    , NoUnused.Modules.rule
    , NoUnused.Parameters.rule
    , NoUnused.Patterns.rule
    , NoUnusedPorts.rule
    , NoUnused.Variables.rule
    , NoUselessSubscriptions.rule
    , ReviewPipelineStyles.rule <|
        List.concat
            [ noMultilineLeftPizza
            , noSingleLineRightPizza
            , noSinglePiplinesWithSimpleInputs
            , noRepeatedParentheticalApplication
            , noPipelinesWithConfusingNonCommutativeFunctions
            , noSemanticallyInfixFunctionsInLeftPipelines
            ]
    , Simplify.rule Simplify.defaults
    , UseCamelCase.rule UseCamelCase.default
    ]
        |> List.map
            (Rule.ignoreErrorsForFiles
                [ "src/Html/Tailwind.elm"
                , "src/Svg/Tailwind.elm"
                ]
            )
        |> List.map
            (Rule.ignoreErrorsForDirectories
                [ "gen"
                ]
            )
