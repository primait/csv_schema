defmodule BuddyTest do
  use ExUnit.Case

  # Now primary key is buddy_id
  test "Get by id. When id exists in csv returns a buddy" do
    assert Buddy.by_buddy_id("Roarke Loynton").__struct__ == Buddy
  end

  test "Get by id. When id doesn't exists in csv returns nil" do
    assert is_nil(Buddy.by_buddy_id("Jack Sparrow"))
  end

  test "Get by unique field. When field value exists in csv returns a buddy" do
    assert Buddy.by_email("ahavick1b@discovery.com").__struct__ == Buddy
  end

  test "Get by unique field. When field value doesn't exists in csv returns nil" do
    assert is_nil(Buddy.by_email("ajeje.brazorf@prima.it"))
  end

  test "Filter by field. When value matches returns array of buddies" do
    assert "Male" |> Buddy.filter_by_gender() |> Enum.count() == 494
  end

  test "Filter by field. When value doesn't match return empty array" do
    assert "Ajeje" |> Buddy.filter_by_first_name() == []
  end

  test "Get all returns all buddies" do
    assert Buddy.get_all() |> Enum.count() == 1000
  end
end
