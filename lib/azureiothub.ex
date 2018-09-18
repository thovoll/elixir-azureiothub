defmodule AzureIoTHub do
  alias AzureIoTHub.Client

  defdelegate connect(), to: Client
end
