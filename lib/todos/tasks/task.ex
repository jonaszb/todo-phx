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
    |> validate_required([:title, :done], message: "Title cannot be empty")
    |> validate_length(:title, max: 80, message: "Title cannot exceed 80 characters")
  end
end
