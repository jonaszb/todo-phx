defmodule Todos.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :done, :boolean, default: false
    field :title, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :done])
    |> validate_required([:title, :done])
  end
end
