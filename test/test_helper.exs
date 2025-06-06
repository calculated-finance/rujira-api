ExUnit.start()
Mox.defmock(Rujira.Events.PublisherMock, for: Rujira.Events.Publisher)
Application.put_env(:rujira, Rujira.Events, publisher: Rujira.Events.PublisherMock)
Ecto.Adapters.SQL.Sandbox.mode(Rujira.Repo, :manual)

# Load all fixture modules under test/fixtures/
Path.wildcard(Path.expand("fixtures/**/*.ex", __DIR__))
|> Enum.each(&Code.require_file/1)
