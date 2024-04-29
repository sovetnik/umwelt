# Umwelt ![ExUnit, Credo & Dialyzer](https://github.com/sovetnik/umwelt/actions/workflows/elixir.yml/badge.svg?event=push)
Client for [umwelt.dev](https://umwelt.dev)

## Implemented actions:

### Dump

Extracts Umwelt from Elixir project and dumps it into `project_name.bin`

## Installation

[available in Hex](https://hex.pm/packages/umwelt), the package can be installed
by adding `umwelt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:umwelt, "~> 0.1.0"}
  ]
end
```

## Usage

Right now it is a proof of concept, and in this version parser can parse some business-logic related code, via `mix dump`.


## Planned
Here is the list of planned features:

### Client functions
Set of push/pull/sync mix tasks to sync local code with remote representation on [umwelt.dev](https://umwelt.dev)

### Unparser
Tools for update local code with changes made on web side.
