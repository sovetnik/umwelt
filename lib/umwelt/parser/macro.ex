defmodule Umwelt.Parser.Macro do
  @moduledoc "Parses various AST"

  alias Umwelt.Felixir.Call
  alias Umwelt.Parser

  import Umwelt.Parser.Operator, only: [is_operator: 1]
  import Umwelt.Parser.Pipe, only: [is_pipe_operator: 1]
  import Umwelt.Parser.Sigil, only: [is_sigil: 1]
  import Umwelt.Parser.Structure, only: [is_structure: 1]

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

  def parse({_, _, nil} = ast, _aliases, _context),
    do: Parser.Literal.parse(ast)

  def parse({:@, _, [{_, _, nil}]} = ast, _aliases, _context),
    do: Parser.Literal.parse(ast)

  def parse({:@, _, _} = ast, aliases, context),
    do: Parser.Attrs.parse(ast, aliases, context)

  def parse({:alias, _, _} = ast, aliases, context),
    do: Parser.Aliases.parse(ast, aliases, context)

  def parse({:__aliases__, _, _} = ast, aliases, context),
    do: Parser.Aliases.parse(ast, aliases, context)

  def parse({term, _, _} = ast, _aliases, context)
      when term in [:defmodule] and is_macro(ast),
      do: Parser.Defmodule.parse(ast, context)

  def parse({term, _, _} = ast, _aliases, context)
      when term in [:defprotocol] and is_macro(ast),
      do: Parser.Defprotocol.parse(ast, context)

  def parse({term, _, _} = ast, aliases, context)
      when term in [:defstruct] and is_macro(ast),
      do: Parser.Defstruct.parse(ast, aliases, context)

  def parse({:defguard, _, [{:when, _, _} = when_ast]}, aliases, context),
    do: %{defguard: parse(when_ast, aliases, context)}

  def parse({term, _, _} = ast, aliases, context)
      when term in ~w|def defp|a,
      do: Parser.Def.parse(ast, aliases, context)

  def parse({term, _, _} = ast, aliases, context)
      when is_macro(ast) and is_structure(term),
      do: Parser.Structure.parse(ast, aliases, context)

  def parse({term, _, _} = ast, aliases, context)
      when is_operator(term),
      do: Parser.Operator.parse(ast, aliases, context)

  def parse({{term, _, _}, _, _} = ast, aliases, context)
      when is_operator(term),
      do: Parser.Operator.parse(ast, aliases, context)

  def parse({term, _, _} = ast, aliases, context)
      when is_pipe_operator(term),
      do: Parser.Pipe.parse(ast, aliases, context)

  def parse({term, _, _} = ast, aliases, _context)
      when is_sigil(term),
      do: Parser.Sigil.parse(ast, aliases)

  # skip unquote
  def parse({{:unquote, _, _}, _, _}, _, _),
    do: %{unquoted: []}

  # simple call node
  def parse({term, _, children} = ast, aliases, context)
      when is_atom_macro(ast),
      do: %Call{
        context: context,
        name: to_string(term),
        arguments: Parser.parse_list(children, aliases, context),
        type: Parser.Literal.type_of(:any)
      }
end
