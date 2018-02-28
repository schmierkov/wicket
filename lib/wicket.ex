defmodule Wicket do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    slack_token = Application.get_env(:wicket, Wicket)[:slack_token]

    # Define workers and child supervisors to be supervised
    children = [
      worker(__MODULE__, [], function: :run),
      worker(Slack.Bot, [Wicket.Bot, [], slack_token])
    ]

    opts = [strategy: :one_for_one, name: Wicket.Supervisor]

    {:ok, _pid} = Supervisor.start_link(children, opts)
  end

  def run do
    routes = [{"/", Wicket.Handler, []}]
    dispatch = :cowboy_router.compile([{:_, routes}])
    port = Application.get_env(:wicket, Wicket)[:http_port]
    opts = [port: port]
    env = [dispatch: dispatch]
    {:ok, _pid} = :cowboy.start_http(:http, 100, opts, [env: env])
  end
end
