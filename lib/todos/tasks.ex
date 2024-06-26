defmodule Todos.Tasks do
  @moduledoc """
  The Tasks context.
  """

  @topic inspect(__MODULE__)
  import Ecto.Query, warn: false
  alias Todos.Repo

  alias Todos.Tasks.Task

  @doc """
  Returns the list of tasks.

  ## Examples

      iex> list_tasks()
      [%Task{}, ...]

  """
  def list_tasks do
    Repo.all(from t in Task, order_by: [desc: t.id])
  end

  def list_tasks(filter) when is_map(filter) do
    from(t in Task, order_by: [desc: t.id])
    |> filter_by_status(filter)
    |> Repo.all()
  end

  def count_tasks() do
    from(Task) |> where(done: false) |> Repo.aggregate(:count)
  end

  def filter_by_status(query, %{done: done}) do
    where(query, done: ^done)
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Todos.PubSub, @topic)
  end

  def broadcast({:ok, msg}, tag) do
    Phoenix.PubSub.broadcast(Todos.PubSub, @topic, {tag, msg})
    {:ok, msg}
  end

  def broadcast({:error, _changeset} = error, _tag), do: error

  @doc """
  Gets a single task.

  Raises `Ecto.NoResultsError` if the Task does not exist.

  ## Examples

      iex> get_task!(123)
      %Task{}

      iex> get_task!(456)
      ** (Ecto.NoResultsError)

  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Creates a task.

  ## Examples

      iex> create_task(%{field: value})
      {:ok, %Task{}}

      iex> create_task(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_task(attrs \\ %{}) do
    if from(Task) |> Repo.aggregate(:count) >= 100 do
      {:error, "Cannot create more than 100 tasks"}
    else
      %Task{}
      |> Task.changeset(attrs)
      |> Repo.insert()
      |> broadcast(:task_created)
    end
  end

  @doc """
  Updates a task.

  ## Examples

      iex> update_task(task, %{field: new_value})
      {:ok, %Task{}}

      iex> update_task(task, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
    |> broadcast(:task_updated)
  end

  @doc """
  Deletes a task.

  ## Examples

      iex> delete_task(task)
      {:ok, %Task{}}

      iex> delete_task(task)
      {:error, %Ecto.Changeset{}}

  """
  def delete_task(%Task{} = task) do
    Repo.delete(task) |> broadcast(:task_deleted)
  end

  def delete_done_tasks() do
    {count, _} = from(t in Task, where: t.done == true) |> Repo.delete_all()
    if count > 0, do: broadcast({:ok, count}, :done_tasks_deleted)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.

  ## Examples

      iex> change_task(task)
      %Ecto.Changeset{data: %Task{}}

  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end
end
