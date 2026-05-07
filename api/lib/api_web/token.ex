defmodule ApiWeb.Token do
  use Joken.Config

  def max_age do
    # 7 days in seconds
    60 * 60 * 24 * 7
  end
end
