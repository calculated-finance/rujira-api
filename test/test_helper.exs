ExUnit.start()
Mox.defmock(Rujira.Events.PublisherMock, for: Rujira.Events.Publisher)
Application.put_env(:rujira, Rujira.Events, publisher: Rujira.Events.PublisherMock)
Ecto.Adapters.SQL.Sandbox.mode(Rujira.Repo, :manual)

# Load everything in test/support/
Path.wildcard(Path.expand("support/**/*.exs", __DIR__))
|> Enum.each(&Code.require_file(&1, __DIR__))
