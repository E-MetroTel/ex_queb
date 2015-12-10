# ExQueb

Generic Ecto Query Builder

This is a helper library for sharing code between ex_admin and auth-ex 
projects.

## Installation

Add ex_queb to your deps:

mix.exs
```elixir
  defp deps do
     ...
     {:ex_queb, github: "E-MetroTel/ex_queb"}, 
     ...
  end
```

Fetch and compile the dependency

```mix do deps.get, deps.compile```

## TODO

This implementation contains code that is subject to SQL or Elixir 
code injection. Need to re-factor.

## License

`ex_eueb` is Copyright (c) 2015 E-MetroTel

The source code is released under the MIT License.

Check [LICENSE](LICENSE) for more information.
