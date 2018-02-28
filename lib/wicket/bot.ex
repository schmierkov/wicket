defmodule Wicket.Bot do
  use Slack

  def handle_connect(_slack, state) do
    # IO.puts "Connected as #{slack.me.name}"
    {:ok, state}
  end

  def handle_event(message = %{type: "message"}, slack, state) do
    if Regex.run ~r/<@#{slack.me.id}>:?\s/, message.text do
      command_parser(message, slack)
    end
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

    if "<@#{slack.me.id}>" == Enum.at(command_list, 0) do
      main_cmd = Enum.at(command_list, 1)
        |> String.to_atom()

      List.delete_at(command_list, 0)
        |> List.replace_at(0, main_cmd)
        |> process_command(message.user, message.channel, slack)
    end
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
      [%{"price_eur" => euro}] = Poison.decode!(body)
      "#{euro} €"
    rescue
      Poison.SyntaxError -> "kann dat nich lesen"
    end
  end

  def process_command([:coin, currency], _user, channel, slack) do
    get_currency(currency)
    |> extract_value()
    |> send_message(channel, slack)
  end
  def process_command([:slap], user, channel, slack),      do: send_message("<@#{user}> slap", channel, slack)
  def process_command([:slap, victim], _, channel, slack), do: send_message("patsch patsch straight in #{victim} sei Gsischt!", channel, slack)
  def process_command([:ping], user, channel, slack),      do: send_message("<@#{user}> pong", channel, slack)
  def process_command([:ping, victim], _, channel, slack), do: send_message("#{victim} pong", channel, slack)
  def process_command([:joke], _, channel, slack),         do: send_message("y u no funny?", channel, slack)
  def process_command(_, user, channel, slack),            do: send_message("<@#{user}> I don't know this command.", channel, slack)
end
