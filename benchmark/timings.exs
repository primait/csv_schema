# iex -S mix
# c "timings.exs"
# Enum.each(1..5, fn _ -> c "benchmark/timings.exs" end)

defmodule Utils do
  def t({micros, _}), do: IO.inspect(micros)
end

:timer.tc(fn -> IEx.Helpers.c("benchmark/A.01.R1_000.KN.U0.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.02.R1_000.KS.U1.F1.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.03.R1_000.KS.U2.F2.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.04.R1_000.KS.U2.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.05.R1_000.KS.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.06.R1_000.KS.U0.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.07.R1_000.KN.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/A.08.R1_000.KN.U0.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.01.R5_000.KN.U0.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.02.R5_000.KS.U1.F1.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.03.R5_000.KS.U2.F2.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.04.R5_000.KS.U2.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.05.R5_000.KS.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.06.R5_000.KS.U0.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.07.R5_000.KN.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/B.08.R5_000.KN.U0.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.01.R10_000.KN.U0.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.02.R10_000.KS.U1.F1.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.03.R10_000.KS.U2.F2.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.04.R10_000.KS.U2.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.05.R10_000.KS.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.06.R10_000.KS.U0.F4.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.07.R10_000.KN.U2.F0.exs") end) |> Utils.t()
:timer.tc(fn -> IEx.Helpers.c("benchmark/C.08.R10_000.KN.U0.F4.exs") end) |> Utils.t()
IO.inspect("=======================================")
