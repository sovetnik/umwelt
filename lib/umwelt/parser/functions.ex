defmodule Umwelt.Parser.Functions do
  @moduledoc "Parses Module AST"

  # require Logger
  # @log_message "Unknown AST skipped in Functions."

  alias Umwelt.Argument
  alias Umwelt.Felixir.{Function, Operator, Signature, Value}
  alias Umwelt.Parser.Types

  import Umwelt.Parser.Util, only: [string_or: 2]

  def combine(block_children, types) do
    index = Enum.into(types, %{}, &{&1.name, &1})

    block_children
    |> extract(index)
    |> Enum.map(&Types.specify(&1, index))
  end

  # here we extract functions from list of parsed module children
  def extract(block_children, index) do
    Enum.reduce([[%Function{}] | block_children], fn
      %{moduledoc: _value} = element, acc
      when not is_struct(element) ->
        acc

      %{doc: [value]} = element, [head | rest]
      when not is_struct(element) ->
        [Map.put(head, :note, string_or(value, "fun description")) | rest]

      %{impl: [value]}, [head | rest] ->
        [Map.put(head, :impl, clean_value(value)) | rest]

      %{spec: value} = element, [head | rest]
      when not is_struct(element) ->
        [Map.put(head, :body, Types.specify(value, index)) | rest]

      %Operator{name: "when"} = when_op, [head | rest] ->
        [%Function{}, when_op, head | rest]

      %Function{} = function, [head | rest] ->
        [
          %Function{},
          function
          |> Map.put(:impl, head.impl)
          |> Map.put(:note, head.note)
          |> Argument.resolve(head.body)
          | rest
        ]

      %Signature{} = signature, [head | rest] ->
        [
          %Function{},
          signature
          |> Signature.merge(head)
          | rest
        ]

      _other, acc ->
        # Logger.warning("#{@log_message}extract_functions/1\n #{inspect(other, pretty: true)}")
        acc
    end)
    |> Enum.reject(&match?(%{body: nil}, &1))
    |> Enum.reverse()
  end

  defp clean_value(%Value{type: %{type: :boolean}, body: "true"}), do: true
  defp clean_value(%Value{type: %{type: :boolean}, body: "false"}), do: false
  defp clean_value(%Value{} = value), do: value
end
