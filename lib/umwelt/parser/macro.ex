defmodule Umwelt.Parser.Macro do
  @moduledoc "Parses various AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Comparison, only: [is_comparison: 1]

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

  def parse({:|>, _, _} = ast, aliases),
    do: Parser.Pipe.parse(ast, aliases)

  def parse({:__aliases__, _, module} = ast, aliases) when is_macro(ast),
    do: expand_module(module, aliases)

  def parse({:defmodule, _, _} = ast, context) when is_macro(ast),
    do: Parser.Defmodule.parse(ast, context)

  def parse({:def, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Def.parse(ast, aliases)

  # guard call, like is_atom, etc.
  def parse({:when, _, children} = ast, aliases) when is_atom_macro(ast),
    do: Parser.parse(children, aliases)

  def parse({:{}, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Tuple.parse(ast, aliases)

  def parse({:=, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Match.parse(ast, aliases)

  def parse({:%, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Struct.parse(ast, aliases)

  def parse({:%{}, _, children} = ast, _aliases) when is_macro(ast),
    do: %{struct: children}

  def parse({:\\, _, children} = ast, aliases) when is_macro(ast),
    do: %{default_arg: Parser.parse(children, aliases)}

  def parse({:., _, children} = ast, aliases) when is_macro(ast),
    do: %{call: Parser.parse(children, aliases)}

  def parse({{:., _, [{:__aliases__, _, [:Kernel]}, term]}, _, arguments}, aliases)
      when is_atom(term),
      do: Parser.parse({term, [], arguments}, aliases)

  def parse({term, _, _} = ast, aliases) when is_comparison(term),
    do: Parser.Comparison.parse(ast, aliases)

  def parse({term, [from_brackets: true, line: _], [from, key]} = ast, aliases)
      when is_macro_macro(ast) do
    %{
      struct: parse(term, aliases),
      brackets: %{
        from: Parser.parse(from, aliases),
        key: Parser.parse(key, aliases)
      }
    }
  end

  # access get
  def parse({term, _, []} = ast, aliases) when is_macro_macro(ast),
    do: parse(term, aliases)

  # guard call, like is_atom, etc.
  def parse({term, _, children} = ast, aliases) when is_atom_macro(ast),
    do: %{guard: Parser.parse(term, aliases), target_arg: Parser.parse(children, aliases)}

  defp expand_module(module, []), do: module

  defp expand_module([head | rest], aliases) do
    aliases
    |> Enum.filter(&match?([^head | _], Enum.reverse(&1)))
    |> List.flatten()
    |> Kernel.++(rest)
  end
end
