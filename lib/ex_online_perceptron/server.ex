defmodule ExOnlinePerceptron.Server do

  def start_link(filename, port) do
    :gen_server.start_link({:local, :ex_online_perceptron}, __MODULE__, {filename, port}, [])
  end


  def init({filename, port}) do
    {:ok, listen} = :gen_tcp.listen(port, [:binary, {:packet, :line}, {:active, false}, {:reuseaddr, true}])
    IO.puts "listening port: #{port}"
    accept(listen, filename)
  end

  def stop() do
    :ok
  end

  defp accept(listen, filename) do
    {:ok, sock} = :gen_tcp.accept(listen)
    IO.puts "new client connection\n"
    spawn(__MODULE__, :process_command, [sock, filename])
    accept(listen, filename)
  end

  def process_command(sock, filename) do
    case :gen_tcp.recv(sock, 0) do
      {:ok, line} ->
        token = String.split(String.strip(line))
        case token do
          ["train" | score_and_bag_of_words ] ->
            process_train(sock, score_and_bag_of_words, filename)
          ["predict" | bag_of_words] ->
            process_predict(sock, bag_of_words, filename)
          _ ->
            :gen_tcp.send(sock, "UNKNOWN COMMAND\r\n")
        end
        process_command(sock, filename)
     {:error, :closed} ->
       IO.puts "closed"
     _ ->
       IO.puts "Error"
    end
  end

  defp get_weight(key) do
    case :dets.lookup(__MODULE__, key) do
      [{_, value}] -> value
      [] -> 0
    end
  end

  defp predict([], score) do
    score
  end

  defp predict([h|t], score) do
    predict(t, score + get_weight(h))
  end

  defp train([], score) do
    :ok
  end

  defp train([h|l], score) do
    :dets.insert(__MODULE__, {h, get_weight(h) + score})
    train(l, score)
  end

  defp process_train(sock, score_and_bag_of_words, filename) do
    {:ok, ref} = :dets.open_file(__MODULE__, {:file, filename})
    case score_and_bag_of_words do
      [binary_score | bag_of_words] ->
        score = binary_to_integer(binary_score, 10)
        predicted = predict(bag_of_words, 0)
        IO.puts "predicted: #{predicted}"
        if (score * predicted < 1) do
          train(bag_of_words, score)
          IO.puts "trained"
        end
        :gen_tcp.send(sock, "TRAINED\r\n")
      _ ->
        :gen_tcp.send(sock, "TRAIN ERROR\r\n")
    end
    :dets.close(__MODULE__)
  end

  defp process_predict(sock, bag_of_words, filename) do
    {:ok, ref} = :dets.open_file(__MODULE__, {:file, filename})
    predicted = predict(bag_of_words, 0)
    :dets.close(__MODULE__)
    :gen_tcp.send(sock, "PREDICTED: #{predicted}\r\n")
  end

end
