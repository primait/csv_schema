defmodule Csv.Schema.Parser do
  @moduledoc """
  Utility module containing some functions for parsing and to read CSV file.
  """

  @doc """
  Given a CSV file path try to parse as CSV with headers.

  Use list of maps as data representation.
  """
  @spec csv!(Enumerable.t(), boolean, pos_integer) :: Enumerable.t() | no_return
  def csv!(stream, headers, separator = ?;), do: csv(stream, headers, separator)
  def csv!(stream, headers, separator = ?,), do: csv(stream, headers, separator)
  def csv!(stream, headers, separator = ?\t), do: csv(stream, headers, separator)
  def csv!(stream, headers, separator = ?\s), do: csv(stream, headers, separator)
  def csv!(stream, headers, separator = ?|), do: csv(stream, headers, separator)
  def csv!(_, _, s), do: raise("Separator '#{s}' should be a codepoint and one of ';' ',' '\\t' '\\s' '|'")

  @spec csv(Enumerable.t(), boolean, pos_integer) :: Enumerable.t() | no_return
  defp csv(stream, headers, separator) do
    stream
    |> CSV.decode(separator: separator, headers: headers)
    |> Stream.map(fn
      {:error, reason} -> raise "Failed to parse line with reason #{reason}"
      {:ok, row} -> row
    end)
  end

  @doc """
  Having a string or an atom as input cast value to atom. If something else is
  given an exception is raised.

  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.atom!("")
      nil

      iex> Csv.Schema.Parser.atom!(nil)
      nil

      iex> Csv.Schema.Parser.atom!("id")
      :id

      iex> Csv.Schema.Parser.atom!(:id)
      :id

      iex> Csv.Schema.Parser.atom!(1)
      ** (RuntimeError) Cannot cast '1' to atom
  """
  @spec atom!(String.t() | atom) :: atom | nil | no_return
  def atom!(""), do: nil
  def atom!(nil), do: nil
  def atom!(value) when is_atom(value), do: value
  def atom!(value) when is_binary(value), do: String.to_atom(value)
  def atom!(value), do: raise("Cannot cast '#{value}' to atom")

  @doc """
  Having a string or an atom as input cast value to string.

  If something else is given an exception is raised.
  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.string!("")
      nil

      iex> Csv.Schema.Parser.string!(nil)
      nil

      iex> Csv.Schema.Parser.string!("id")
      "id"

      iex> Csv.Schema.Parser.string!(:id)
      "id"

      iex> Csv.Schema.Parser.string!(1)
      ** (RuntimeError) Cannot cast '1' to string
  """
  @spec string!(String.t() | atom) :: String.t() | nil | no_return
  def string!(""), do: nil
  def string!(nil), do: nil
  def string!(value) when is_binary(value), do: value
  def string!(value) when is_atom(value), do: Atom.to_string(value)
  def string!(value), do: raise("Cannot cast '#{value}' to string")

  @doc """
  Having a string as input cast value to integer.

  If something else is given an exception is raised.
  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.integer!("")
      nil

      iex> Csv.Schema.Parser.integer!(nil)
      nil

      iex> Csv.Schema.Parser.integer!("1")
      1

      iex> Csv.Schema.Parser.integer!("1a")
      ** (RuntimeError) Cannot cast '1a' to integer
  """
  @spec integer!(String.t()) :: number | nil | no_return
  def integer!(""), do: nil
  def integer!(nil), do: nil

  def integer!(value) do
    case Integer.parse(value) do
      {val, ""} -> val
      _ -> raise "Cannot cast '#{value}' to integer"
    end
  end

  @doc """
  Having a string as input cast value to float.

  If something else is given an exception is raised.
  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.float!("")
      nil

      iex> Csv.Schema.Parser.float!(nil)
      nil

      iex> Csv.Schema.Parser.float!("1.2")
      1.2

      iex> Csv.Schema.Parser.float!("1a")
      ** (RuntimeError) Cannot cast '1a' to float
  """
  @spec float!(String.t()) :: number | nil | no_return
  def float!(""), do: nil
  def float!(nil), do: nil

  def float!(value) do
    case Float.parse(value) do
      {val, ""} -> val
      _ -> raise "Cannot cast '#{value}' to float"
    end
  end

  @doc """
  Having a string as input representing string date to parse and a string
  representing the date format try to cast value to date.

  If something else is given or format is invalid or date is not parsable with
  given format an exception is raised.
  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.date!("", "whatever")
      nil

      iex> Csv.Schema.Parser.date!(nil, "whatever")
      nil

      iex> Csv.Schema.Parser.date!("18/01/2019", "{0D}/{0M}/{0YYYY}")
      ~N[2019-01-18 00:00:00]

      iex> Csv.Schema.Parser.date!("18/01/2019", "{0M}/{0D}/{0YYYY}")
      ** (RuntimeError) Cannot cast '18/01/2019' to date with format '{0M}/{0D}/{0YYYY}'

      iex> Csv.Schema.Parser.date!("18/01/2019", "MDY")
      ** (RuntimeError) Invalid date format 'MDY'
  """
  @spec date!(String.t(), String.t()) :: DateTime.t() | nil | no_return
  def date!("", _), do: nil
  def date!(nil, _), do: nil

  def date!(value, format) do
    case Timex.validate_format(format) do
      :ok ->
        case Timex.parse(value, format) do
          {:ok, date} -> date
          {:error, _} -> raise "Cannot cast '#{value}' to date with format '#{format}'"
        end

      {:error, _} ->
        raise "Invalid date format '#{format}'"
    end
  end

  @doc """
  Having a string as input cast value to boolean.

  If something else is given an exception is raised.

  If given argument is empty string or nil return value will be nil.

  ## Examples

      iex> Csv.Schema.Parser.boolean!("")
      nil

      iex> Csv.Schema.Parser.boolean!(nil)
      nil

      iex> Csv.Schema.Parser.boolean!("true")
      true

      iex> Csv.Schema.Parser.boolean!("false")
      false

      iex> Csv.Schema.Parser.boolean!("1a")
      ** (RuntimeError) Cannot cast '1a' to boolean
  """
  @spec boolean!(String.t()) :: boolean | nil | no_return
  def boolean!(""), do: nil
  def boolean!(nil), do: nil
  def boolean!("true"), do: true
  def boolean!("false"), do: false
  def boolean!(value), do: raise("Cannot cast '#{value}' to boolean")
end
