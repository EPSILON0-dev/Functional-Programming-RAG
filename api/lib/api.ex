defmodule Api do
  @moduledoc """
  Api keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def __using__(which) when is_atom(which) do
    apply(__MODULE__, :"__#{which}__", [])
  end

  def __controller__ do
    quote do
      use Phoenix.Controller, namespace: Api

      import Plug.Conn
      import Api.Gettext
    end
  end
end
