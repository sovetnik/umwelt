# Umwelt ![Umwelt CI](https://github.com/sovetnik/umwelt/actions/workflows/elixir.yml/badge.svg?event=push) [![wakatime](https://wakatime.com/badge/user/7542de1a-027f-4ed7-bc4b-c31d4cf9aa2a/project/018c9f92-bb93-4303-816f-bc0799a61194.svg)](https://wakatime.com/badge/user/7542de1a-027f-4ed7-bc4b-c31d4cf9aa2a/project/018c9f92-bb93-4303-816f-bc0799a61194)
Client for [umwelt.dev](https://umwelt.dev)

## Implemented actions:

### Dump

Extracts Umwelt from Elixir project and dumps it into `root_name.bin`

## Installation

[available in Hex](https://hex.pm/packages/umwelt), the package can be installed
by adding `umwelt` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:umwelt, "~> 0.1"}
  ]
end
```

## Usage

Right now it is a proof of concept, and in this version parser can parse some business-logic related code, via `mix dump`.

In common case, when you want to parse your project and it's name from `Mix.Project.config()[:app]` matches root folder name `lib/root_name`, use:
```bash
  mix dump
```

When you wanna parse another folder in lib, `lib/another_root_name`, use:
```bash
  mix dump another_root_name
```


## Planned
Here is the list of planned features:

### Client functions
Set of push/pull/sync mix tasks to sync local code with remote representation on [umwelt.dev](https://umwelt.dev)

### Unparser
Tools for update local code with changes made on web side.
