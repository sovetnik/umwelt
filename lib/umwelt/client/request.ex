defmodule Umwelt.Client.Request do
  @moduledoc "Umwelt client request"

  require Logger

  def fetch_modules(params) do
    ~c"#{params.api_host}:#{params.port}/api/trees/#{params.phase_id}"
    |> do_request(params.token)
    |> handle_response()
  end

  def fetch_code(params) do
    ~c"#{params.api_host}:#{params.port}/api/code/#{params.phase_id}/#{params.id}"
    |> do_request(params.token)
    |> handle_response()
  end

  defp do_request(url, token) do
    :httpc.request(:get, {url, headers(token)}, [], [])
  end

  defp handle_response({:ok, {{~c"HTTP/1.1", 200, ~c"OK"}, _headers, body}}) do
    {:ok, Jason.decode!(body)["data"]}
  end

  defp handle_response({:ok, {{~c"HTTP/1.1", _status, _reason}, _headers, body}}) do
    %{"error" => reason} = Jason.decode!(body)
    {:error, reason}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end

  defp headers(token) do
    [
      {~c"Authorization", ~c"Bearer #{token}"},
      {~c"Accept", ~c"application/json"}
    ]
  end
end
