defmodule ExQueb.Utils do
  import Ecto.Query

  def get_entry_type(query, entry) do
    module = query_to_module(query)
    cond do
      module.__schema__(:type, entry) -> :field
      module.__schema__(:association, entry) -> :assoc
      true -> nil
    end
  end

  def query_to_module(%Ecto.Query{from: %{source: {_table_name, module}}}) do
    module
  end

  def query_to_module(other), do: query_to_module(from(q in other))

  # Warn: as param is not used, and is set statically to the :query value.
  # TODO: fix this
  # See: https://github.com/elixir-ecto/ecto/pull/3465#issuecomment-826796922
  def build_exists_subquery(query, assoc, _as) do
    case query_to_module(query).__schema__(:association, assoc) do
      %Ecto.Association.ManyToMany{
        queryable: association,
        join_through: join_through,
        join_keys: [{through_owner_key, owner_key}, {through_assoc_key, assoc_key}]
      } ->
        from(a in association,
          join: jt in ^join_through,
          on:
            field(a, ^assoc_key) == field(jt, ^through_assoc_key) and
            field(jt, ^through_owner_key) == field(parent_as(:query), ^owner_key)
        )
      %type{
        queryable: association,
        related_key: related_key,
        owner_key: owner_key
      } when type in [Ecto.Association.Has, Ecto.Association.BelongsTo] ->
        from(
          a in association,
          where: field(a, ^related_key) == field(parent_as(:query), ^owner_key)
        )
    end
  end

end