# iex -S mix
# c "benchmark/timings.exs"

defmodule Utils do
  # Compilation benchmark utils
  def measure_compile_time(benchmark_files, additions) do
    Enum.map(benchmark_files, fn file ->
      module_content = file |> File.read!() |> Utils.random_module_name() |> additions.()

      fn -> Code.compile_string(module_content) end
      |> :timer.tc()
      |> Utils.t()
    end)
  end

  def t({micros, [{module, _}]}) do
    IO.puts("#{module} -> #{pad(to_string(micros))} µs")
    module
  end

  def random_module_name(content) do
    [head | tail] = String.split(content, "\n")
    Enum.join([String.replace(head, " do", ".T#{:os.system_time(:millisecond)} do") | tail], "\n")
  end

  # Function call benchmark utils
  def measure_runtime(modules) do
    Enum.map(modules, fn module ->
      num_of_rows = :materialized |> module.get_all() |> Enum.count() |> to_string()

      {by_micros, _} =
        case prepare(module, "by_") do
          nil ->
            {"-", ""}

          {by_function, by_values} ->
            :timer.tc(fn ->
              Enum.each(1..1_000, fn _ ->
                Enum.each(by_values, &apply(module, by_function, [&1]))
              end)
            end)
        end

      {filter_by_micros, _} =
        case prepare(module, "filter_by_") do
          nil ->
            {"-", ""}

          {filter_by_function, filter_values} ->
            :timer.tc(fn ->
              Enum.each(1..1_000, fn _ ->
                Enum.each(filter_values, &apply(module, filter_by_function, [&1]))
              end)
            end)
        end

      by_millis_per_operation = if is_binary(by_micros), do: by_micros, else: to_string(by_micros / 100_000)

      filter_by_millis_per_operation =
        if is_binary(filter_by_micros), do: filter_by_micros, else: to_string(filter_by_micros / 100_000)

      IO.puts(
        "#{module} -> #{pad(by_millis_per_operation)} µs/op | #{pad(to_string(by_micros))} |#{
          pad(filter_by_millis_per_operation)
        } µs/op | #{pad(to_string(filter_by_micros))} |#{pad(num_of_rows)} | 100000"
      )
    end)
  end

  defp prepare(module, fun_string) do
    case find_function(module, fun_string) do
      nil -> nil
      {fun, key} -> {String.to_atom("#{fun}#{key}"), fetch_random_values(module, key)}
    end
  end

  defp find_function(module, fun_string) do
    :functions
    |> module.__info__()
    |> Enum.map(&(&1 |> elem(0) |> to_string()))
    |> Enum.map(fn binary ->
      if String.starts_with?(binary, fun_string) do
        {String.to_atom(fun_string), binary |> String.replace(fun_string, "") |> String.to_atom()}
      end
    end)
    |> Enum.find(&(not is_nil(&1)))
  end

  defp fetch_random_values(module, key) do
    module |> apply(:get_all, []) |> Enum.take_random(100) |> Enum.map(&Map.get(&1, key))
  end

  # Common
  def pad(string), do: String.pad_leading(string, 12)
end

benchmark_files = [
  "benchmark/A.01.R1_000.KN.U0.F0.exs",
  "benchmark/A.02.R1_000.KS.U1.F1.exs",
  "benchmark/A.03.R1_000.KS.U2.F2.exs",
  "benchmark/A.04.R1_000.KS.U2.F4.exs",
  "benchmark/A.05.R1_000.KS.U2.F0.exs",
  "benchmark/A.06.R1_000.KS.U0.F4.exs",
  "benchmark/A.07.R1_000.KN.U2.F0.exs",
  "benchmark/A.08.R1_000.KN.U0.F4.exs",
  "benchmark/B.01.R5_000.KN.U0.F0.exs",
  "benchmark/B.02.R5_000.KS.U1.F1.exs",
  "benchmark/B.03.R5_000.KS.U2.F2.exs",
  "benchmark/B.04.R5_000.KS.U2.F4.exs",
  "benchmark/B.05.R5_000.KS.U2.F0.exs",
  "benchmark/B.06.R5_000.KS.U0.F4.exs",
  "benchmark/B.07.R5_000.KN.U2.F0.exs",
  "benchmark/B.08.R5_000.KN.U0.F4.exs",
  "benchmark/C.01.R10_000.KN.U0.F0.exs",
  "benchmark/C.02.R10_000.KS.U1.F1.exs",
  "benchmark/C.03.R10_000.KS.U2.F2.exs",
  "benchmark/C.04.R10_000.KS.U2.F4.exs",
  "benchmark/C.05.R10_000.KS.U2.F0.exs",
  "benchmark/C.06.R10_000.KS.U0.F4.exs",
  "benchmark/C.07.R10_000.KN.U2.F0.exs",
  "benchmark/C.08.R10_000.KN.U0.F4.exs"
]

IO.puts("\n============ COMPILATION ============")

modules = Utils.measure_compile_time(benchmark_files, & &1)

IO.puts("\n============= EXECUTION =============")

Utils.measure_runtime(modules)
