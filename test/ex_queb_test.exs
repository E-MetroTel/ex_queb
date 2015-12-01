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

  test "no filter" do
    query_equal ExQueb.filter(Test.Model, %{}), Test.Model
  end

  def query_equal(a, b) do
    assert a == b
  end
end
