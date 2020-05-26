module Vendor.NoUnused.Parameters exposing (rule)

{-| Report parameters that are not used.


# Rule

@docs rule

-}

import Elm.Syntax.Declaration as Declaration exposing (Declaration)
import Elm.Syntax.Expression as Expression exposing (Expression)
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.Pattern as Pattern exposing (Pattern)
import Elm.Syntax.Range as Range exposing (Range)
import Elm.Writer as Writer
import Review.Fix as Fix
import Review.Rule as Rule exposing (Rule)
import Set exposing (Set)
import Vendor.NoUnused.Patterns.NameVisitor as NameVisitor


{-| Report parameters that are not used.

    config =
        [ NoUnused.Parameters.rule
        ]

This rule looks within function arguments, let functions and lambdas to find any values that are unused. It will report any parameters that are not used.


## Fixes for lambdas

We're only offering fixes for lambdas here because we believe unused parameters in functions are a code smell that should be refactored.


## Fail

Value `something` is not used:

    add1 number =
        1


## Success

    add1 number =
        number + 1

-}
rule : Rule
rule =
    Rule.newModuleRuleSchema "NoUnused.Parameters" initialContext
        |> Rule.withDeclarationVisitor declarationVisitor
        |> Rule.withExpressionVisitor expressionVisitor
        |> NameVisitor.withValueVisitor valueVisitor
        |> Rule.fromModuleRuleSchema


declarationVisitor : Node Declaration -> Rule.Direction -> Context -> ( List (Rule.Error {}), Context )
declarationVisitor node direction context =
    case ( direction, Node.value node ) of
        ( Rule.OnEnter, Declaration.FunctionDeclaration { declaration } ) ->
            ( [], rememberFunctionImplementation declaration context )

        ( Rule.OnExit, Declaration.FunctionDeclaration { declaration } ) ->
            errorsForFunctionImplementation declaration context

        _ ->
            ( [], context )


expressionVisitor : Node Expression -> Rule.Direction -> Context -> ( List (Rule.Error {}), Context )
expressionVisitor (Node _ expression) direction context =
    case ( direction, expression ) of
        ( Rule.OnEnter, Expression.LambdaExpression { args } ) ->
            ( [], rememberPatternList args context )

        ( Rule.OnExit, Expression.LambdaExpression { args } ) ->
            errorsForPatternList Lambda args context

        ( Rule.OnEnter, Expression.LetExpression { declarations } ) ->
            ( [], rememberLetDeclarationList declarations context )

        ( Rule.OnExit, Expression.LetExpression { declarations } ) ->
            errorsForLetDeclarationList declarations context

        _ ->
            ( [], context )


valueVisitor : Node ( ModuleName, String ) -> Context -> ( List (Rule.Error {}), Context )
valueVisitor (Node _ ( moduleName, value )) context =
    case moduleName of
        [] ->
            ( [], useValue value context )

        _ ->
            ( [], context )



--- ON ENTER


rememberFunctionImplementation : Node Expression.FunctionImplementation -> Context -> Context
rememberFunctionImplementation (Node _ { arguments }) context =
    rememberPatternList arguments context


rememberLetDeclarationList : List (Node Expression.LetDeclaration) -> Context -> Context
rememberLetDeclarationList list context =
    List.foldl rememberLetDeclaration context list


rememberLetDeclaration : Node Expression.LetDeclaration -> Context -> Context
rememberLetDeclaration (Node _ letDeclaration) context =
    case letDeclaration of
        Expression.LetFunction { declaration } ->
            rememberLetFunctionImplementation declaration context

        Expression.LetDestructuring _ _ ->
            context


rememberLetFunctionImplementation : Node Expression.FunctionImplementation -> Context -> Context
rememberLetFunctionImplementation (Node _ { arguments }) context =
    rememberPatternList arguments context


rememberPatternList : List (Node Pattern) -> Context -> Context
rememberPatternList list context =
    List.foldl rememberPattern context list


rememberPattern : Node Pattern -> Context -> Context
rememberPattern (Node _ pattern) context =
    case pattern of
        Pattern.AllPattern ->
            context

        Pattern.VarPattern value ->
            rememberValue value context

        Pattern.TuplePattern patterns ->
            rememberPatternList patterns context

        Pattern.RecordPattern values ->
            rememberValueList values context

        Pattern.UnConsPattern first second ->
            context
                |> rememberPattern first
                |> rememberPattern second

        Pattern.ListPattern patterns ->
            rememberPatternList patterns context

        Pattern.NamedPattern _ patterns ->
            rememberPatternList patterns context

        Pattern.AsPattern inner name ->
            context
                |> rememberPattern inner
                |> rememberValue (Node.value name)

        Pattern.ParenthesizedPattern inner ->
            rememberPattern inner context

        _ ->
            context


rememberValueList : List (Node String) -> Context -> Context
rememberValueList list context =
    List.foldl (Node.value >> rememberValue) context list



--- ON EXIT


singularDetails : List String
singularDetails =
    [ "You should either use this parameter somewhere, or remove it at the location I pointed at." ]


pluralDetails : List String
pluralDetails =
    [ "You should either use these parameters somewhere, or remove them at the location I pointed at." ]


removeDetails : List String
removeDetails =
    [ "You should remove it at the location I pointed at." ]


andThen :
    (Context -> ( List (Rule.Error {}), Context ))
    -> ( List (Rule.Error {}), Context )
    -> ( List (Rule.Error {}), Context )
andThen function ( errors, context ) =
    let
        ( newErrors, newContext ) =
            function context
    in
    ( newErrors ++ errors, newContext )


errorsForFunctionImplementation : Node Expression.FunctionImplementation -> Context -> ( List (Rule.Error {}), Context )
errorsForFunctionImplementation (Node _ { arguments }) context =
    errorsForPatternList Function arguments context


errorsForLetDeclarationList : List (Node Expression.LetDeclaration) -> Context -> ( List (Rule.Error {}), Context )
errorsForLetDeclarationList list context =
    case list of
        [] ->
            ( [], context )

        first :: rest ->
            context
                |> errorsForLetDeclaration first
                |> andThen (errorsForLetDeclarationList rest)


errorsForLetDeclaration : Node Expression.LetDeclaration -> Context -> ( List (Rule.Error {}), Context )
errorsForLetDeclaration (Node _ letDeclaration) context =
    case letDeclaration of
        Expression.LetFunction { declaration } ->
            errorsForLetFunctionImplementation declaration context

        Expression.LetDestructuring _ _ ->
            ( [], context )


errorsForLetFunctionImplementation : Node Expression.FunctionImplementation -> Context -> ( List (Rule.Error {}), Context )
errorsForLetFunctionImplementation (Node _ { arguments }) context =
    errorsForPatternList Function arguments context


type PatternUse
    = Lambda
    | Function


errorsForPatternList : PatternUse -> List (Node Pattern) -> Context -> ( List (Rule.Error {}), Context )
errorsForPatternList use list context =
    case list of
        [] ->
            ( [], context )

        first :: rest ->
            context
                |> errorsForPattern use first
                |> andThen (errorsForPatternList use rest)


errorsForPattern : PatternUse -> Node Pattern -> Context -> ( List (Rule.Error {}), Context )
errorsForPattern use (Node range pattern) context =
    case pattern of
        Pattern.AllPattern ->
            ( [], context )

        Pattern.VarPattern value ->
            errorsForValue use value range context

        Pattern.RecordPattern values ->
            errorsForRecordValueList use range values context

        Pattern.TuplePattern [ Node _ Pattern.AllPattern, Node _ Pattern.AllPattern ] ->
            errorsForUselessTuple use range context

        Pattern.TuplePattern [ Node _ Pattern.AllPattern, Node _ Pattern.AllPattern, Node _ Pattern.AllPattern ] ->
            errorsForUselessTuple use range context

        Pattern.TuplePattern patterns ->
            errorsForPatternList use patterns context

        Pattern.UnConsPattern first second ->
            errorsForPatternList use [ first, second ] context

        Pattern.ListPattern patterns ->
            errorsForPatternList use patterns context

        Pattern.NamedPattern _ patterns ->
            if List.all isAllPattern patterns then
                errorsForUselessNamePattern use range context

            else
                errorsForPatternList use patterns context

        Pattern.AsPattern inner name ->
            context
                |> errorsForAsPattern use range inner name
                |> andThen (errorsForPattern use inner)

        Pattern.ParenthesizedPattern inner ->
            errorsForPattern use inner context

        _ ->
            ( [], context )


errorsForUselessNamePattern : PatternUse -> Range -> Context -> ( List (Rule.Error {}), Context )
errorsForUselessNamePattern use range context =
    let
        fix =
            case use of
                Lambda ->
                    [ Fix.replaceRangeBy range "_" ]

                Function ->
                    []
    in
    ( [ Rule.errorWithFix
            { message = "Named pattern is not needed."
            , details = removeDetails
            }
            range
            fix
      ]
    , context
    )


errorsForUselessTuple : PatternUse -> Range -> Context -> ( List (Rule.Error {}), Context )
errorsForUselessTuple use range context =
    let
        fix =
            case use of
                Lambda ->
                    [ Fix.replaceRangeBy range "_" ]

                Function ->
                    []
    in
    ( [ Rule.errorWithFix
            { message = "Tuple pattern is not needed."
            , details = removeDetails
            }
            range
            fix
      ]
    , context
    )


errorsForRecordValueList : PatternUse -> Range -> List (Node String) -> Context -> ( List (Rule.Error {}), Context )
errorsForRecordValueList use recordRange list context =
    let
        ( unused, used ) =
            List.partition (\(Node _ value) -> Set.member value context) list
    in
    case unused of
        [] ->
            ( [], context )

        firstNode :: restNodes ->
            let
                first =
                    firstNode |> Node.value

                rest =
                    List.map Node.value restNodes

                errorRange =
                    Range.combine (List.map Node.range unused)

                fix =
                    case ( use, used ) of
                        ( Lambda, [] ) ->
                            [ Fix.replaceRangeBy recordRange "_" ]

                        ( Lambda, _ ) ->
                            [ Node Range.emptyRange (Pattern.RecordPattern used)
                                |> Writer.writePattern
                                |> Writer.write
                                |> Fix.replaceRangeBy recordRange
                            ]

                        ( Function, _ ) ->
                            []
            in
            ( [ Rule.errorWithFix
                    { message = listToMessage first rest
                    , details = listToDetails first rest
                    }
                    errorRange
                    fix
              ]
            , List.foldl forgetNode context unused
            )


listToMessage : String -> List String -> String
listToMessage first rest =
    case List.reverse rest of
        [] ->
            "Parameter `" ++ first ++ "` is not used."

        last :: middle ->
            "Parameters `" ++ String.join "`, `" (first :: middle) ++ "` and `" ++ last ++ "` are not used."


listToDetails : String -> List String -> List String
listToDetails _ rest =
    case rest of
        [] ->
            singularDetails

        _ ->
            pluralDetails


errorsForAsPattern : PatternUse -> Range -> Node Pattern -> Node String -> Context -> ( List (Rule.Error {}), Context )
errorsForAsPattern use patternRange inner (Node range name) context =
    if Set.member name context then
        let
            fix =
                case use of
                    Lambda ->
                        [ inner
                            |> Writer.writePattern
                            |> Writer.write
                            |> Fix.replaceRangeBy patternRange
                        ]

                    Function ->
                        []
        in
        ( [ Rule.errorWithFix
                { message = "Pattern alias `" ++ name ++ "` is not used."
                , details = singularDetails
                }
                range
                fix
          ]
        , Set.remove name context
        )

    else if isAllPattern inner then
        ( [ Rule.errorWithFix
                { message = "Pattern `_` is not needed."
                , details = removeDetails
                }
                (Node.range inner)
                [ Fix.replaceRangeBy patternRange name ]
          ]
        , Set.remove name context
        )

    else
        ( [], context )


isAllPattern : Node Pattern -> Bool
isAllPattern (Node _ pattern) =
    case pattern of
        Pattern.AllPattern ->
            True

        _ ->
            False


forgetNode : Node String -> Context -> Context
forgetNode (Node _ value) context =
    Set.remove value context



--- CONTEXT


type alias Context =
    Set String


initialContext : Context
initialContext =
    Set.empty


errorsForValue : PatternUse -> String -> Range -> Context -> ( List (Rule.Error {}), Context )
errorsForValue use value range context =
    if Set.member value context then
        let
            fix =
                case use of
                    Lambda ->
                        [ Fix.replaceRangeBy range "_" ]

                    Function ->
                        []
        in
        ( [ Rule.errorWithFix
                { message = "Parameter `" ++ value ++ "` is not used."
                , details = singularDetails
                }
                range
                fix
          ]
        , Set.remove value context
        )

    else
        ( [], context )


rememberValue : String -> Context -> Context
rememberValue value context =
    Set.insert value context


useValue : String -> Context -> Context
useValue value context =
    Set.remove value context
