defmodule AzureIoTHub do
  alias AzureIoTHub.Client

  defdelegate connect_and_publish(), to: Client
end
