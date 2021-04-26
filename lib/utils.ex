defmodule ExQueb.Utils do
  import Ecto.Query

  def query_to_module(%Ecto.Query{from: %{source: {_table_name, module}}}) do
    module
  end

  def query_to_module(other), do: query_to_module(from(q in other))

  def get_assoc_data(query, assoc) do
    case query_to_module(query).__schema__(:association, assoc) do
      %{
        queryable: queryable,
        related_key: related_key,
        owner_key: owner_key
      } -> {queryable, owner_key, related_key}
    end
  end

  # Warn: as param is not used, and is set statically to the :query value.
  # TODO: fix this
  # See: https://github.com/elixir-ecto/ecto/pull/3465#issuecomment-826796922
  def build_exists_subquery(query, assoc, _as) do
    {assoc_struct, owner_key, foreign_key} = get_assoc_data(query, assoc)
    from(a in assoc_struct, where: field(a, ^foreign_key) == field(parent_as(:query), ^owner_key))
  end

end