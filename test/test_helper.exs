ExUnit.start()
Mox.defmock(Rujira.Events.PublisherMock, for: Rujira.Events.Publisher)
Application.put_env(:rujira, Rujira.Events, publisher: Rujira.Events.PublisherMock)
Ecto.Adapters.SQL.Sandbox.mode(Rujira.Repo, :manual)
