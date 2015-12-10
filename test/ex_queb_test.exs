defmodule Test.Model do
  use Ecto.Model
  schema "models" do
    field :name, :string
    field :age, :integer

    timestamps
  end
end

defmodule ExQuebTest do
  use ExUnit.Case
  doctest ExQueb
  import Ecto.Query

  test "no filter" do
    assert_equal ExQueb.filter(Test.Model, %{}), Test.Model
  end

  # %{blog_id_eq: "1", inserted_at_gte: nil, inserted_at_lte: nil, name_contains: nil, updated_at_gte: nil, updated_at_lte: nil}
  test "filters single field" do
    expected = where(Test.Model, [m], like(m.name, "%Test%"))
    assert_equal ExQueb.filter(Test.Model, %{q: %{name_contains: "Test"}}), expected
  end

  def assert_equal(a, b) do
    assert inspect(a) == inspect(b)
  end
end
