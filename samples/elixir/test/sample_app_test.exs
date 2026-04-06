defmodule SampleAppTest do
  use ExUnit.Case, async: true

  test "returns a greeting" do
    assert SampleApp.greeting() == "hello from the elixir sample"
  end
end
