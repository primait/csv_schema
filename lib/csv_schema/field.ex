defmodule Csv.Schema.Field do
  @moduledoc false

  alias Csv.Schema.Parser

  defstruct name: nil,
            column: nil,
            parser: &Parser.string!/1,
            key: false,
            unique: false,
            filter_by: false,
            join: ""

  @type t :: %__MODULE__{}

  @doc false
  @spec new(atom, String.t(), Keyword.t()) :: t
  def new(name, column, opts) when is_number(column), do: _new(name, column, opts)
  def new(name, column, opts) when is_binary(column), do: _new(name, column, opts)
  def new(name, column, opts) when is_list(column), do: check_values(name, column, opts)
  def new(name, column, _), do: raise("Column should be an header name or a column index. Given: '#{name}:#{column}'")

  defp check_values(name, column, opts) do
    cond do
      Enum.all?(column, &is_binary/1) -> _new(name, column, opts)
      Enum.all?(column, &is_number/1) -> _new(name, column, opts)
      true -> raise "Given composite key array contains non binary, non number or mixed values #{column}"
    end
  end

  defp _new(name, column, opts) do
    struct!(__MODULE__,
      name: name,
      column: column,
      parser: Keyword.get(opts, :parser, &Parser.string!/1),
      key: Keyword.get(opts, :key, false),
      unique: Keyword.get(opts, :unique, false),
      filter_by: Keyword.get(opts, :filter_by, false),
      join: Keyword.get(opts, :join, "")
    )
  end
end
