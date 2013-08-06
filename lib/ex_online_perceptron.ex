defmodule ExOnlinePerceptron do
  use Application.Behaviour

  def start(_type, [filename, port]) do
    ExOnlinePerceptron.Supervisor.start_link(filename, binary_to_integer(port))
  end
end
