defmodule Umwelt.Parser.Macro do
  @moduledoc "Parses various AST"

  alias Umwelt.Parser

  import Umwelt.Parser.Comparsion, only: [is_comparsion: 1]

  defguard is_macro(term) when is_tuple(term) and tuple_size(term) == 3

  def parse({_, _, nil} = ast, _aliases),
    do: Parser.Literal.parse(ast)

  # def parse({:@, _, _} = ast, _aliases),
  #   do: Parser.Attrs.parse(ast)

  def parse({:__aliases__, _, module} = ast, aliases) when is_macro(ast),
    do: expand_module(module, aliases)

  def parse({:defmodule, _, _} = ast, context) when is_macro(ast),
    do: Parser.Defmodule.parse(ast, context)

  def parse({:def, _, _} = ast, aliases) when is_macro(ast),
    do: Parser.Def.parse(ast, aliases)

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

  # fun call
  def parse({:., _, children} = ast, aliases) when is_macro(ast),
    do: %{call: Parser.parse(children, aliases)}

  def parse({term, _, _} = ast, aliases) when is_comparsion(term),
    do: Parser.Comparsion.parse(ast, aliases)

  def parse({term, [from_brackets: true, line: _], [from, key]} = ast, aliases)
      when is_macro(ast) and is_macro(term) do
    %{
      struct: parse(term, aliases),
      brackets: %{
        from: Parser.parse(from, aliases),
        key: Parser.parse(key, aliases)
      }
    }
  end

  # access get
  def parse({term, _, []} = ast, aliases)
      when is_macro(ast) and is_macro(term),
      do: parse(term, aliases)

  # guard call
  def parse({term, _, children} = ast, aliases)
      when is_macro(ast) and is_atom(term) do
    %{guard: Parser.parse(term, aliases), target_arg: Parser.parse(children, aliases)}
  end

  defp expand_module(module, []), do: module

  defp expand_module([head | rest], aliases) do
    aliases
    |> Enum.filter(&match?([^head | _], Enum.reverse(&1)))
    |> List.flatten()
    |> Kernel.++(rest)
  end
end
