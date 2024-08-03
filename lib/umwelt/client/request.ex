defmodule Umwelt.Client.Request do
  @moduledoc "Umwelt client request"

  require Logger

  def fetch_modules(params) do
    url = ~c"#{params.api_host}:#{params.port}/api/trees/#{params.phase_id}"

    case do_request(url, params.token) do
      {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, _headers, body}} ->
        {:ok, Jason.decode!(body)["data"]}

      {:ok, {{~c"HTTP/1.1", _status, _reason}, _headers, body}} ->
        %{"error" => reason} = Jason.decode!(body)

        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_code(params) do
    url = ~c"#{params.api_host}:#{params.port}/api/code/#{params.phase_id}/#{params.id}"

    case do_request(url, params.token) do
      {:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, _headers, body}} ->
        {:ok, Jason.decode!(body)["data"]}

      {:ok, {{~c"HTTP/1.1", _status, _reason}, _headers, body}} ->
        %{"error" => reason} = Jason.decode!(body)
        {:error, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp do_request(url, token) do
    :httpc.request(:get, {url, headers(token)}, [], [])
  end

  defp headers(token) do
    [
      {~c"Authorization", ~c"Bearer #{token}"},
      {~c"Accept", ~c"application/json"}
    ]
  end
end
