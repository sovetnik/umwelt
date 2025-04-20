defprotocol Umwelt.Argument do
  @moduledoc "All about types"

  @doc "Resolves type of left term"
  def resolve(left, right)
end

defimpl Umwelt.Argument, for: List do
  def resolve(arguments, types) do
    arguments
    |> Enum.zip(types)
    |> Enum.map(fn {left, right} ->
      Umwelt.Argument.resolve(left, right)
    end)
  end
end
