defmodule Bugsnag do
  @notifier_info %{
    name: "Bugsnag Elixir",
    version: "0.0.1",
    url: "https://github.com/jarednorman/bugsnag-elixir",
  }
  @notify_url "https://notify.bugsnag.com"
  @request_headers [{"Content-Type", "application/json"}]

  use HTTPoison.Base

  # Public

  # Currently we only support reporting exceptions.
  def report(%{__exception__: true} = exception, stacktrace) do
    post(@notify_url,
         payload(exception, stacktrace) |> to_json,
         @request_headers)
  end

  # Private

  def payload(exception, stacktrace) do
    %{}
    |> add_api_key
    |> add_notifier_info
    |> add_event(exception, stacktrace)
  end

  defp to_json(payload) do
    payload
    |> JSEX.encode
    |> elem(1)
  end

  defp add_api_key(payload) do
    { _, api_key } = :application.get_env(:bugsnag, :api_key)
    Map.put payload, :apiKey, api_key
  end

  defp add_notifier_info(payload)do
    Map.put payload, :notifier, @notifier_info
  end

  defp add_event(payload, exception, stacktrace) do
    Map.put payload, :events, [ %{
      payloadVersion: "2",
      exceptions: [ %{
        errorClass: exception.__struct__,
        message: Exception.message(exception),
        stacktrace: format_stacktrace(stacktrace)
      } ],
      severity: "error"
    } ]
  end

  defp format_stacktrace(stacktrace) do
    Enum.map stacktrace, fn
      ({ module, function, arity, [] }) ->
        %{
          file: "unknown",
          lineNumber: 0,
          method: "#{ module }.#{ function }/#{ arity }"
        }
      ({ module, function, arity, [ file: file, line: line_number ] }) ->
        %{
          file: file |> List.to_string,
          lineNumber: line_number,
          method: "#{ module }.#{ function }/#{ arity }"
        }
    end
  end
end