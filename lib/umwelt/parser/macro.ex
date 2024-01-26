defmodule Umwelt.Parser.Macro do
  @moduledoc "Parses various AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Comparison, only: [is_comparison: 1]
  import Umwelt.Parser.Operator, only: [is_operator: 1]
  import Umwelt.Parser.Pipe, only: [is_pipe_operator: 1]

  # defguard is_macro(term) when is_tuple(term) and tuple_size(term) == 3

  defguard is_atom_macro(term)
           when is_tuple(term) and
                  tuple_size(term) == 3 and
                  is_atom(elem(term, 0)) and
                  (is_list(elem(term, 1)) or is_nil(elem(term, 1))) and
                  (is_list(elem(term, 2)) or is_atom(elem(term, 2)))

  defguard is_macro_macro(term)
           when is_tuple(term) and
                  tuple_size(term) == 3 and
                  is_atom_macro(elem(term, 0)) and
                  (is_list(elem(term, 1)) or is_nil(elem(term, 1))) and
                  (is_list(elem(term, 2)) or is_atom(elem(term, 2)))

  defguard is_macro(term) when is_atom_macro(term) or is_macro_macro(term)

  def parse({_, _, nil} = ast, _aliases),
    do: Parser.Literal.parse(ast)

  # def parse({:@, _, _} = ast, _aliases),
  #   do: Parser.Attrs.parse(ast)

  def parse({:__aliases__, _, module} = ast, aliases) when is_macro(ast),
    do: Parser.expand_module(module, aliases)

  def parse({:defmodule, _, _} = ast, context) when is_macro(ast),
    do: Parser.Defmodule.parse(ast, context)

  def parse({:def, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Def.parse(ast, aliases)

  # guard call, like is_atom, etc.
  def parse({:when, _, children} = ast, aliases) when is_atom_macro(ast),
    do: Parser.parse(children, aliases)

  def parse({:{}, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Tuple.parse(ast, aliases)

  def parse({:%, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Struct.parse(ast, aliases)

  def parse({:%{}, _, children} = ast, _aliases) when is_macro(ast),
    do: %{struct: children}

  # access get
  def parse({term, _, []} = ast, aliases) when is_macro_macro(ast),
    do: Parser.parse(term, aliases)

  def parse({term, _, _} = ast, aliases) when is_operator(term),
    do: Parser.Operator.parse(ast, aliases)

  def parse({{term, _, _}, _, _} = ast, aliases) when is_operator(term),
    do: Parser.Operator.parse(ast, aliases)

  def parse({term, _, _} = ast, aliases) when is_pipe_operator(term),
    do: Parser.Pipe.parse(ast, aliases)

  def parse({term, _, _} = ast, aliases) when is_comparison(term),
    do: Parser.Comparison.parse(ast, aliases)

  # guard call, like is_atom, etc.
  def parse({term, _, children} = ast, aliases) when is_atom_macro(ast) do
    # IO.inspect(ast, label: :term_ast)
    # IO.inspect(term, label: :term)
    %{guard: Parser.parse(term, aliases), target_arg: Parser.parse(children, aliases)}
  end
end
