defmodule AzureIoTHub.Client do
  def connect_and_publish() do
    iot_hub_host_name = config(:iot_hub_host_name)
    iot_hub_host_port = config(:iot_hub_host_port)
    device_id = config(:device_id)
    device_key = config(:device_key)
    ttl_in_sec = 86400 # 1 day

    IO.puts("Connecting to #{iot_hub_host_name}:#{iot_hub_host_port} using device ID '#{device_id}'...")

    result = Tortoise.Supervisor.start_child(
      client_id: device_id,
      handler: {Tortoise.Handler.Logger, []},
      server: {
        Tortoise.Transport.SSL, 
        verify: :verify_none,
        host: iot_hub_host_name, 
        port: iot_hub_host_port
      },
      user_name: device_user_name(iot_hub_host_name, device_id),
      password: device_password(iot_hub_host_name, device_id, device_key, ttl_in_sec),
      subscriptions: []
    ) 

    case result do
      {:ok, _pid} -> IO.puts("Started.")
      {:error, {:already_started, _pid}} -> IO.puts("Already started.")
    end

    topic = events_topic(device_id)
    IO.puts("Publishing to topic #{topic}...")
    Tortoise.publish(device_id, topic, "Hello Azure IoT Hub!", qos: 0)
    IO.puts("Done.")
  end

  defp config(key) do
    Application.get_env(:azureiothub, key)
  end

  defp device_user_name(host_name, device_id) do
    "#{host_name}/#{device_id}/api-version=2016-11-14"
  end

  defp device_password(host_name, device_id, device_key, ttl_in_sec) do
    uri = "#{host_name}/devices/#{device_id}" |> URI.encode_www_form 
    expiry = System.system_time(:second) + ttl_in_sec
    plain_text = "#{uri}\n#{expiry}"
    decoded_device_key = device_key |> Base.decode64! 

    signature = 
      :crypto.hmac(:sha256, decoded_device_key, plain_text)
      |> Base.encode64
      |> URI.encode_www_form

    "SharedAccessSignature sig=#{signature}&se=#{expiry}&sr=#{uri}"
  end

  defp events_topic(device_id) do
    "devices/#{device_id}/messages/events/"
  end
end