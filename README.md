# Umwelt ![Umwelt CI](https://github.com/sovetnik/umwelt/actions/workflows/elixir.yml/badge.svg?event=push) [![wakatime](https://wakatime.com/badge/user/7542de1a-027f-4ed7-bc4b-c31d4cf9aa2a/project/018c9f92-bb93-4303-816f-bc0799a61194.svg)](https://wakatime.com/badge/user/7542de1a-027f-4ed7-bc4b-c31d4cf9aa2a/project/018c9f92-bb93-4303-816f-bc0799a61194)
Client for [umwelt.dev](https://umwelt.dev)

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

### Dump

Extracts Umwelt from Elixir project and dumps it into `root_name.bin`

In common case, when you want to parse your project and it's name from `Mix.Project.config()[:app]` matches root folder name `lib/root_name`, use:
```bash
  mix umwelt.dump
```

When you wanna parse another folder in lib, `lib/another_root_name`, use:
```bash
  mix umwelt.dump another_root_name
```

### Clone

Fetch and write all modules from specified phase.

When your project is ready, you can get its code and specs.
Create a new elixir or phoenix app, add umwelt and pull the code.
```bash
  mix new project_name
  cd project_name
```
add umwelt to deps in `mix.exs`.

You have to obtain a token on [profile page](https://umwelt.dev/auth/profile) 
```bash
  export UMWELT_TOKEN="your_token"
  mix umwelt.clone phase_id
  mix test --trace
```
And now you will see all messages for failing tests and can start coding.

If you want to reduce logger add this to your `config.exs`
```
    config :logger,
      compile_time_purge_matching: [
        [application: :umwelt, level_lower_than: :warning]
      ]
```

## Planned
Here is the list of planned features:

### Client functions
Set of pull/push/sync mix tasks to sync local code with remote representation on [umwelt.dev](https://umwelt.dev)

### Unparser
Tools for update local code with changes made on web side.
