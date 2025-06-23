# This file contains the configuration for Credo and you are probably reading
# this after creating it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      #
      # Load and configure plugins here:
      #
      plugins: [],
      #
      # If you create your own checks, you must specify the source files for
      # them here, so they can be loaded by Credo before running the analysis.
      #
      requires: [],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      strict: true,
      #
      # To modify the timeout for parsing files, change this value:
      #
      parse_timeout: 5000,
      #
      # If you want to use uncolored output by default, you can change `color`
      # to `false` below:
      #
      color: true,
      #
      # You can customize the parameters of any check by adding a second element
      # to the tuple.
      #
      # To disable a check put `false` as second element:
      #
      #     {Credo.Check.Design.DuplicatedCode, false}
      #
      checks: %{
        enabled: [
          #
          ## Consistency Checks
          #
          {Credo.Check.Consistency.ExceptionNames, [exit_status: 1]},
          {Credo.Check.Consistency.LineEndings, [exit_status: 1]},
          {Credo.Check.Consistency.ParameterPatternMatching, [exit_status: 1]},
          {Credo.Check.Consistency.SpaceAroundOperators, [exit_status: 1]},
          {Credo.Check.Consistency.SpaceInParentheses, [exit_status: 1]},
          {Credo.Check.Consistency.TabsOrSpaces, [exit_status: 1]},

          #
          ## Design Checks
          #
          # You can customize the priority of any check
          # Priority values are: `low, normal, high, higher`
          #
          {Credo.Check.Design.AliasUsage,
           [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 0]},
          {Credo.Check.Design.TagFIXME, []},
          # You can also customize the exit_status of each check.
          # If you don't want TODO comments to cause `mix credo` to fail, just
          # set this value to 0 (zero).
          #
          {Credo.Check.Design.TagTODO, [exit_status: 0]},

          #
          ## Readability Checks
          #
          {Credo.Check.Readability.AliasOrder, [exit_status: 1]},
          {Credo.Check.Readability.FunctionNames, [exit_status: 1]},
          {Credo.Check.Readability.LargeNumbers, [exit_status: 1]},
          {Credo.Check.Readability.MaxLineLength,
           [priority: :low, max_length: 120, exit_status: 1]},
          {Credo.Check.Readability.ModuleAttributeNames, [exit_status: 1]},
          {Credo.Check.Readability.ModuleDoc, [exit_status: 1]},
          {Credo.Check.Readability.ModuleNames, [exit_status: 1]},
          {Credo.Check.Readability.ParenthesesInCondition, [exit_status: 1]},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, [exit_status: 1]},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, [exit_status: 1]},
          {Credo.Check.Readability.PredicateFunctionNames, [exit_status: 1]},
          {Credo.Check.Readability.PreferImplicitTry, [exit_status: 1]},
          {Credo.Check.Readability.RedundantBlankLines, [exit_status: 1]},
          {Credo.Check.Readability.Semicolons, [exit_status: 1]},
          {Credo.Check.Readability.SpaceAfterCommas, [exit_status: 1]},
          {Credo.Check.Readability.StringSigils, [exit_status: 1]},
          {Credo.Check.Readability.TrailingBlankLine, [exit_status: 1]},
          {Credo.Check.Readability.TrailingWhiteSpace, [exit_status: 1]},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, [exit_status: 1]},
          {Credo.Check.Readability.VariableNames, [exit_status: 1]},
          {Credo.Check.Readability.WithSingleClause, [exit_status: 1]},

          #
          ## Refactoring Opportunities
          #
          {Credo.Check.Refactor.Apply, [exit_status: 1]},
          {Credo.Check.Refactor.CondStatements, [exit_status: 1]},
          {Credo.Check.Refactor.CyclomaticComplexity, [exit_status: 1]},
          {Credo.Check.Refactor.FilterCount, [exit_status: 1]},
          {Credo.Check.Refactor.FilterFilter, [exit_status: 1]},
          {Credo.Check.Refactor.FunctionArity, [exit_status: 1]},
          {Credo.Check.Refactor.LongQuoteBlocks, [exit_status: 1]},
          {Credo.Check.Refactor.MapJoin, [exit_status: 1]},
          {Credo.Check.Refactor.MatchInCondition, [exit_status: 1]},
          {Credo.Check.Refactor.NegatedConditionsInUnless, [exit_status: 1]},
          {Credo.Check.Refactor.NegatedConditionsWithElse, [exit_status: 1]},
          {Credo.Check.Refactor.Nesting, [exit_status: 1]},
          {Credo.Check.Refactor.RedundantWithClauseResult, [exit_status: 1]},
          {Credo.Check.Refactor.RejectReject, [exit_status: 1]},
          {Credo.Check.Refactor.UnlessWithElse, [exit_status: 1]},
          {Credo.Check.Refactor.WithClauses, [exit_status: 1]},

          #
          ## Warnings
          #
          {Credo.Check.Warning.ApplicationConfigInModuleAttribute, [exit_status: 1]},
          {Credo.Check.Warning.BoolOperationOnSameValues, [exit_status: 1]},
          {Credo.Check.Warning.Dbg, [exit_status: 1]},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, [exit_status: 1]},
          {Credo.Check.Warning.IExPry, [exit_status: 1]},
          {Credo.Check.Warning.IoInspect, [exit_status: 1]},
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig, [exit_status: 1]},
          {Credo.Check.Warning.OperationOnSameValues, [exit_status: 1]},
          {Credo.Check.Warning.OperationWithConstantResult, [exit_status: 1]},
          {Credo.Check.Warning.RaiseInsideRescue, [exit_status: 1]},
          {Credo.Check.Warning.SpecWithStruct, [exit_status: 1]},
          {Credo.Check.Warning.UnsafeExec, [exit_status: 1]},
          {Credo.Check.Warning.UnusedEnumOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedFileOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedKeywordOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedListOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedPathOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedRegexOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedStringOperation, [exit_status: 1]},
          {Credo.Check.Warning.UnusedTupleOperation, [exit_status: 1]},
          {Credo.Check.Warning.WrongTestFileExtension, [exit_status: 1]}
        ],
        disabled: [
          #
          # Checks scheduled for next check update (opt-in for now)
          {Credo.Check.Refactor.UtcNowTruncate, []},

          #
          # Controversial and experimental checks (opt-in, just move the check to `:enabled`
          #   and be sure to use `mix credo --strict` to see low priority checks)
          #
          {Credo.Check.Consistency.MultiAliasImportRequireUse, []},
          {Credo.Check.Consistency.UnusedVariableNames, []},
          {Credo.Check.Design.DuplicatedCode, []},
          {Credo.Check.Design.SkipTestWithoutComment, []},
          {Credo.Check.Readability.AliasAs, []},
          {Credo.Check.Readability.BlockPipe, []},
          {Credo.Check.Readability.ImplTrue, []},
          {Credo.Check.Readability.MultiAlias, []},
          {Credo.Check.Readability.NestedFunctionCalls, []},
          {Credo.Check.Readability.OneArityFunctionInPipe, []},
          {Credo.Check.Readability.OnePipePerLine, []},
          {Credo.Check.Readability.SeparateAliasRequire, []},
          {Credo.Check.Readability.SingleFunctionToBlockPipe, []},
          {Credo.Check.Readability.SinglePipe, []},
          {Credo.Check.Readability.Specs, []},
          {Credo.Check.Readability.StrictModuleLayout, []},
          {Credo.Check.Readability.WithCustomTaggedTuple, []},
          {Credo.Check.Refactor.ABCSize, []},
          {Credo.Check.Refactor.AppendSingleItem, []},
          {Credo.Check.Refactor.DoubleBooleanNegation, []},
          {Credo.Check.Refactor.FilterReject, []},
          {Credo.Check.Refactor.IoPuts, []},
          {Credo.Check.Refactor.MapMap, []},
          {Credo.Check.Refactor.ModuleDependencies, []},
          {Credo.Check.Refactor.NegatedIsNil, []},
          {Credo.Check.Refactor.PassAsyncInTestCases, []},
          {Credo.Check.Refactor.PipeChainStart, []},
          {Credo.Check.Refactor.RejectFilter, []},
          {Credo.Check.Refactor.VariableRebinding, []},
          {Credo.Check.Warning.LazyLogging, []},
          {Credo.Check.Warning.LeakyEnvironment, []},
          {Credo.Check.Warning.MapGetUnsafePass, []},
          {Credo.Check.Warning.MixEnv, []},
          {Credo.Check.Warning.UnsafeToAtom, []}

          # {Credo.Check.Refactor.MapInto, []},

          #
          # Custom checks can be created using `mix credo.gen.check`.
          #
        ]
      }
    }
  ]
}
