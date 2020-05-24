module Vendor.NoRedundantConcat exposing (rule)

{-|

@docs rule

-}

import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.Infix as Infix
import Elm.Syntax.Node as Node exposing (Node)
import Elm.Syntax.Range exposing (Range)
import Review.Fix as Fix
import Review.Rule as Rule exposing (Error, Rule)
import Vendor.NoRedundantConcat.Util as Util


{-| Forbids using list concatenation (++) when it's not needed.

Expressions like `[ a, b ] ++ c` will be flagged, with a fix proposing to
rewrite that to somethine like `a :: b :: c`. This is more performant and makes
it clear that we're talking about consing items to the head of a list. Easy!

Furthermore, expressions like `[ a, b ] ++ [ c, d ]` could be rewritten to a
single literal list: no need to perform the concatenation at runtime when we can
just write it ourselves! So, the fix will propose writing that as `[ a, b, c, d
]`.

To use this rule, add it to your `elm-review` config like so:

    module ReviewConfig exposing (config)

    import NoRedundantConcat
    import Review.Rule exposing (Rule)

    config : List Rule
    config =
        [ NoRedundantConcat.rule
        ]

-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoRedundantConcat" ()
        |> Rule.withSimpleExpressionVisitor expressionVisitor
        |> Rule.fromModuleRuleSchema


expressionVisitor : Node Expression -> List (Error {})
expressionVisitor (Node.Node range expression) =
    case expression of
        Expression.OperatorApplication "++" _ (Node.Node _ (Expression.ListExpr leftItems)) (Node.Node _ (Expression.ListExpr rightItems)) ->
            [ Rule.errorWithFix
                { message = "Concatenating a literal list with another literal list can be written as a single list literal"
                , details =
                    [ "Expressions like `[ foo ] ++ [ bar ]` can be written as `[ foo, bar ]`."
                    , "Using 'complex' expressions when not necessary can make code look a lot more complex than it really is. When you need to put two literal lists together, you can just put them together! No need to have that happen at runtime."
                    ]
                }
                range
                [ combineLists range leftItems rightItems ]
            ]

        Expression.OperatorApplication "++" _ (Node.Node _ (Expression.ListExpr items)) right ->
            [ Rule.errorWithFix
                { message = "Concatenating a literal list with something else can be written using cons operators"
                , details =
                    [ "Expressions like `[ foo ] ++ b` can be written as `foo :: b`."
                    , "This preserves the mental model that `List` is a linked list, with the performance considerations associated with those."
                    ]
                }
                range
                [ concatItems range (List.reverse items) right ]
            ]

        _ ->
            []


combineLists : Range -> List (Node Expression) -> List (Node Expression) -> Fix.Fix
combineLists range left right =
    (left ++ right)
        |> Expression.ListExpr
        |> Util.expressionToString range
        |> Fix.replaceRangeBy range


concatItems : Range -> List (Node Expression) -> Node Expression -> Fix.Fix
concatItems range items ((Node.Node ontoRange ontoExpr) as onto) =
    case items of
        [] ->
            Fix.replaceRangeBy range (Util.expressionToString ontoRange ontoExpr)

        item :: rest ->
            concatItems range
                rest
                (Node.Node ontoRange
                    (Expression.OperatorApplication "::" Infix.Non item onto)
                )
