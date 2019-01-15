defmodule BroTest do
  use ExUnit.Case
  doctest Csv.Schema

  # Now primary key is bro_id
  test "Get by id. When id exists in csv returns a bro" do
    assert Bro.by_bro_id(1).__struct__ == Bro
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Bro.by_bro_id(0))
  end

  test "Get by unique field. When field value exists in csv returns a bro" do
    assert Bro.by_email("mchaplyn9@sciencedaily.com").__struct__ == Bro
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Bro.by_email("ajeje.brazorf@prima.it"))
  end

  test "Filter by field. When value matches returns array of bros" do
    assert "Male" |> Bro.filter_by_gender() |> Enum.count() == 24
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert "Ajeje" |> Bro.filter_by_first_name() == []
  end

  test "Get all returns all bros" do
    assert Bro.get_all() |> Enum.count() == 50
  end
end
