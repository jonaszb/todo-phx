defmodule Todos.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Todos.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        done: true,
        title: "some title"
      })
      |> Todos.Tasks.create_task()

    task
  end
end
