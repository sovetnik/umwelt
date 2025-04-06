defmodule Umwelt.Parser.Call do
  @moduledoc "Parses Call() AST"

  alias Umwelt.Felixir.{Call, Operator}
  alias Umwelt.Parser

  # Mix.Project.config(:dev)[:app]  -> Access after call
  def parse(
        {
          {:., [from_brackets: true, line: _], [Access, :get]},
          [from_brackets: true, line: _],
          [from, key]
        },
        aliases,
        context
      ),
      do: %Operator{
        name: "access",
        left: Parser.parse(from, aliases, context),
        right: Parser.parse(key, aliases, context)
      }

  # Kernel.and(a, b) -> compactize Kernel calls -> and(a, b)
  def parse({{:., _, [{:__aliases__, _, [:Kernel]}, term]}, _, arguments}, aliases, context)
      when is_atom(term),
      do: Parser.parse({term, [], arguments}, aliases, context)

  # String.t() -> just literal
  def parse({{:., _, [{:__aliases__, _, [:String]}, :t]}, _, []}, _, _),
    do: Parser.Literal.type_of(:string)

  # Umwelt.t() -> all calls life this
  def parse({{:., _, [{:__aliases__, _, _} = alias, :t]}, _, []}, aliases, context),
    do: Parser.Aliases.parse(alias, aliases, context)

  # Mix.Task.config() -> qualified call node
  def parse({{:., _, [{:__aliases__, _, module}, term]}, _, arguments}, aliases, context)
      when is_atom(term),
      do: %Call{
        name: to_string(term),
        context: Enum.map(module, &to_string/1),
        arguments: Parser.parse_list(arguments, aliases, context)
      }

  # qualified call erlang
  def parse({{:., _, [erl_module, term]}, _, arguments}, aliases, context)
      when is_atom(erl_module) and is_atom(term),
      do: %Call{
        name: to_string(term),
        context: Parser.parse(erl_module, aliases, context),
        arguments: Parser.parse_list(arguments, aliases, context)
      }

  # foo(bar) -> simpliest case
  def parse({term, _, children}, aliases, context) do
    %Call{
      context: context,
      name: to_string(term),
      arguments: Parser.parse_list(children, aliases, context),
      type: Parser.Literal.type_of(:any)
    }
  end
end
