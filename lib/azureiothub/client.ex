defmodule AzureIoTHub.Client do
  def connect_and_publish() do
    iot_hub_host_name = read_config(:iot_hub_host_name)
    iot_hub_host_port = read_config(:iot_hub_host_port)
    device_id = read_config(:device_id)

    IO.puts("Connecting to #{iot_hub_host_name}:#{iot_hub_host_port} using device ID '#{device_id}'...")

    user_name = "#{iot_hub_host_name}/#{device_id}/api-version=2016-11-14"
    
    signature_string = read_config(:signature_string)
    expiry = read_config(:expiry)
    url_encoded_resource_uri = "#{iot_hub_host_name}%2Fdevices%2F#{device_id}"
    password = "SharedAccessSignature sig=#{signature_string}&se=#{expiry}&sr=#{url_encoded_resource_uri}"

    Tortoise.Supervisor.start_child(
      client_id: device_id,
      handler: {Tortoise.Handler.Logger, []},
      server: {
        Tortoise.Transport.SSL, 
        verify: :verify_none,
        host: iot_hub_host_name, 
        port: iot_hub_host_port
      },
      user_name: user_name,
      password: password ,
      subscriptions: []
    )

    topic = "devices/#{device_id}/messages/events/"
    IO.puts("Publishing to topic #{topic}...")
    Tortoise.publish(device_id, topic, "Hello Azure IoT Hub!", qos: 0)
    IO.puts("Done.")
  end

  defp read_config(key) do
    Application.get_env(:azureiothub, key)
  end
end