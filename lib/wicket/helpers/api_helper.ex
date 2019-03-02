defmodule Wicket.ApiHelper do
  defmacro __using__(_opts) do
    quote do
      import Wicket.ApiHelper
    end
  end

  def json_decode(nil), do: %{}

  def json_decode(body) do
    try do
      Poison.decode!(body)
    rescue
      Poison.SyntaxError -> "kann API daten nich lesen"
    end
  end

  def call_api(nil), do: nil

  def call_api(url) do
    HTTPoison.get!(url)
    |> case do
      %HTTPoison.Response{status_code: 200, body: body} -> body
      _ -> nil
    end
  end

  def get_headers(nil), do: nil

  def get_headers(url) do
    try do
      HTTPoison.get!(url)
      |> case do
        %HTTPoison.Response{status_code: code} -> code
        _ -> "nix"
      end
    rescue
      _ -> "dit war nischt"
    end
  end
end
