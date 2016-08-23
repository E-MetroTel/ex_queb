defmodule ExQueb.StringFilters do
  @moduledoc """
  Build Filters for String Fields.

  String fields can be filtered by the following:

  * begins with
  * ends with
  * contains
  * equals
  """
  import Ecto.Query

  @doc """
  Build a string filter.
  """
  def string_filters(builder, filters) do
    builder
    |> build_string_filters(filters, :begins_with)
    |> build_string_filters(filters, :ends_with)
    |> build_string_filters(filters, :contains)
    |> build_string_filters(filters, :equals)
  end

  defp build_string_filters(builder, filters, type) do
    Enum.filter_map(filters, &(String.match?(elem(&1,0), ~r/_#{type}$/)),
                             &({String.replace(elem(&1, 0), "_#{type}", ""), elem(&1, 1)}))
    |> Enum.reduce(builder, fn({k,v}, acc) ->
      fld = String.to_atom k
      _build_string_filter(acc, fld, v, type)
    end)
  end

  defp _build_string_filter(builder, field, value, :begins_with) do
    match = "#{value}%"
    where(builder, [q], like(field(q, ^field), ^match))
  end

  defp _build_string_filter(builder, field, value, :ends_with) do
    match = "%#{value}"
    where(builder, [q], like(field(q, ^field), ^match))
  end

  defp _build_string_filter(builder, field, value, :contains) do
    match = "%#{value}%"
    where(builder, [q], like(field(q, ^field), ^match))
  end

  defp _build_string_filter(builder, field, value, :equals) do
    where(builder, [q], field(q, ^field) == ^value)
  end

  defp _build_string_filter(builder, field, value, _) do
    where(builder, [q], field(q, ^field) == ^value)
  end
end
