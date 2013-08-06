defmodule ExOnlinePerceptron.Supervisor do
  use Supervisor.Behaviour

  def start_link(filename, port) do
    :supervisor.start_link(__MODULE__, {filename, port})
  end

  def init({filename, port}) do
    childlen = [worker(ExOnlinePerceptron.Server, [filename, port])]
    supervise childlen, strategy: :one_for_one
  end
end
