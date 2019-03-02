defmodule Wicket.Processor.Lol do
  use Wicket.ApiHelper

  @doc ~S"""
  Parses the given `line` into a command.

  ## Examples

      iex> Wicket.LolProcessor.call()
      "rofl"

  """
  def call() do
    reaction_url()
    |> call_api()
    |> json_decode()
    |> Enum.take_random(1)
    |> List.first()
  end

  defp reaction_url() do
    Application.get_env(:wicket, Wicket)[:reaction_url]
  end
end
