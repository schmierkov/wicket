defmodule Wicket.Bot do
  use Slack

  def handle_connect(_slack, state) do
    # IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    command_parser(message, slack)
    {:ok, state}
  end
  def handle_event(_, _, state), do: {:ok, state}

  def handle_info({:message, text, channel}, slack, state) do
    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}

  defp command_parser(message, slack) do
    command_list = String.split(message.text, " ")
    main_cmd = Enum.at(command_list, 1)
               |> String.to_atom()

    command_list
    |> List.replace_at(0, main_cmd)
    |> process_command(message.user, message.channel, slack)
  end

  defp get_currency(currency) do
    HTTPoison.get!("https://api.coinmarketcap.com/v1/ticker/#{currency}/?convert=EUR") |> case do
      %HTTPoison.Response{status_code: 200, body: body} -> body
      _                                                 -> nil
    end
  end

  defp extract_value(nil), do: "API nicht erreichbar"
  defp extract_value(body) do
    try do
      [%{"price_eur" => eur, "price_usd" => usd}] = Poison.decode!(body)
      "#{pretty_price(eur)} € / #{pretty_price(usd)} $"
    rescue
      Poison.SyntaxError -> "kann dat nich lesen"
    end
  end

  defp pretty_price(nil), do: "-"
  defp pretty_price(value) do
    {number, _} = Float.parse(value)
    Float.round(number, 2)
  end

  def process_command([:coin, currency], _user, channel, slack) do
    get_currency(currency)
    |> extract_value()
    |> send_message(channel, slack)
  end
  def process_command([:help], _user, channel, slack), do: send_message("`coin <COIN>` e.g. `coin bitcoin`", channel, slack)
  def process_command([:joke], _user, channel, slack), do: send_message("y u no funny?", channel, slack)
  def process_command(_command, _user, _channel, _slack), do: :noop
end
