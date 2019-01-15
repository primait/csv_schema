defmodule FellowTest do
  use ExUnit.Case
  doctest Csv.Schema

  test "Get by id. When id exists in csv returns a fellow" do
    assert Fellow.by_id(1).__struct__ == Fellow
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Fellow.by_id(0))
  end

  test "Get by unique field. When field value exists in csv returns a fellow" do
    assert Fellow.by_email("mchaplyn9@sciencedaily.com").__struct__ == Fellow
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Fellow.by_email("ajeje.brazorf@prima.it"))
  end

  test "Filter by field. When value matches returns array of Fellows" do
    assert "Male" |> Fellow.filter_by_gender() |> Enum.count() == 24
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert "Ajeje" |> Fellow.filter_by_first_name() == []
  end

  test "Get all returns all fellows" do
    assert Fellow.get_all() |> Enum.count() == 50
  end
end
