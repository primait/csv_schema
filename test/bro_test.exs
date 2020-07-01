defmodule BroTest do
  use ExUnit.Case

  # Now primary key is bro_id
  test "Get by id. When id exists in csv returns a bro" do
    assert Bro.by_bro_id(1).__struct__ == Bro
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Bro.by_bro_id(0))
  end

  test "Get by unique field. When field value exists in csv returns a bro" do
    assert Bro.by_email("pscotteru@scribd.com").__struct__ == Bro
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Bro.by_email("ajeje.brazorf@prima.it"))
  end

  test "Get by unique field. When called with nil, having a nil field in csv, returns nil" do
    assert is_nil(Bro.by_email(nil))
  end

  test "Filter by field. When value matches returns array of bros" do
    assert "Male" |> Bro.filter_by_gender() |> Enum.count() == 494
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert Bro.filter_by_first_name("Ajeje") == []
  end

  test "Filter by field. When value is nil filter records with empty target field" do
    assert nil |> Bro.filter_by_email() |> Enum.count() == 1
  end

  test "Get all returns all bros" do
    assert Enum.count(Bro.get_all()) == 1000
  end
end
