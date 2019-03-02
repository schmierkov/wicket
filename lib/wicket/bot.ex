defmodule Wicket.Bot do
  use Slack
  alias Wicket.Processor.Lol, as: LolProcessor
  use Wicket.ApiHelper

  def handle_connect(_slack, state) do
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
    main_cmd = Enum.at(command_list, 0) |> String.downcase() |> String.to_atom()

    if Enum.member?([:help, :coin, :lol, :curlh], main_cmd) do
      command_list
      |> List.replace_at(0, main_cmd)
      |> Enum.reject(fn x -> x == "" || x == nil end)
      |> process_command(message.user, message.channel, slack)
    end
  end

  defp normalize_value(value) do
    "#{inspect(value)}"
  end

  defp currency_url(currency) do
    "https://api.coinmarketcap.com/v1/ticker/#{currency}/?convert=EUR"
  end

  defp extract_coin_value([
         %{
           "price_eur" => eur,
           "percent_change_1h" => percent_change_1h,
           "percent_change_24h" => percent_change_24h,
           "percent_change_7d" => percent_change_7d
         }
       ]) do
    "#{pretty_price(eur)}€ / 1h change #{percent_change_1h}% / 24h change #{percent_change_24h}% / 7d change #{
      percent_change_7d
    }%"
  end

  defp extract_coin_value(_), do: "Dieser Coin ist mir nicht bekannt, hier ein Keks :cookie:"

  defp pretty_price(nil), do: "-"

  defp pretty_price(value) do
    {number, _} = Float.parse(value)

    if number < 1 do
      number
    else
      Float.round(number, 2)
    end
  end

  defp normalize_url(url) do
    url
    |> String.split("|")
    |> List.first()
    |> String.replace("<", "")
    |> String.replace(">", "")
    |> attach_schema()
  end

  defp attach_schema(url) do
    url
    |> String.starts_with?(["https://", "http://"])
    |> case do
      true -> url
      _ -> "http://#{inspect(url)}"
    end
  end

  defp normalize_currency(value) do
    value
    |> String.downcase()
    |> String.trim()
    |> case do
      "eth" -> "ethereum"
      "btc" -> "bitcoin"
      "ltc" -> "litecoin"
      "bch" -> "bitcoin-cash"
      "xrp" -> "ripple"
      "xrb" -> "nano"
      "ada" -> "cardano"
      other -> other
    end
  end

  def process_command([:coin, currency], _user, channel, slack) do
    currency
    |> normalize_currency()
    |> currency_url()
    |> call_api()
    |> json_decode()
    |> extract_coin_value()
    |> send_message(channel, slack)
  end

  def process_command([:help], _user, channel, slack),
    do: send_message("`coin <COIN>` e.g. `coin bitcoin`", channel, slack)

  def process_command([:curlh, url], _user, channel, slack) do
    url
    |> normalize_url()
    |> get_headers()
    |> normalize_value()
    |> send_message(channel, slack)
  end

  def process_command([:lol], _user, channel, slack) do
    LolProcessor.call()
    |> send_message(channel, slack)
  end

  def process_command(_command, _user, channel, slack) do
    send_message("Eh?!", channel, slack)
  end
end
