defmodule TodosWeb.TaskLive.TaskListComponent do
  use Phoenix.LiveComponent

  alias Todos.Tasks
  import TodosWeb.CoreComponents, only: [icon: 1]

  def mount(socket) do
    {:ok, stream(socket, :tasks, Tasks.list_tasks())}
  end

  def render(assigns) do
    ~H"""
    <div class="hero">
      <%= for {_, task} <- @streams.tasks do %>
        <.todo_item task={task} />
      <% end %>
    </div>
    """
  end

  def todo_item(assigns) do
    ~H"""
    <li class="px-6 py-5 border-b border-[#E3E4F1] dark:border-[#393A4B]">
      <form class="flex gap-6 group">
        <label
          for={@task.id |> Integer.to_string()}
          class="border-[#E3E4F1] dark:border-[#393A4B] rounded-full border transition-all w-6 h-6 flex justify-center cursor-pointer items-center has-[:checked]:bg-gradient-to-br has-[:checked]:from-[#55DDFF] has-[:checked]:to-[#C058F3]"
        >
          <input
            phx-change="toggle_status"
            type="checkbox"
            checked={@task.done}
            class="hidden peer"
            name={@task.id |> Integer.to_string()}
            id={@task.id |> Integer.to_string()}
          />
          <.icon name="hero-check-micro" class="bg-white hidden peer-checked:block" />
        </label>
        <span class="text-lg text-[#494C6B] dark:text-[#C8CBE7] group-has-[:checked]:text-[#D1D2DA] dark:group-has-[:checked]:text-[#4D5067] group-has-[:checked]:line-through transition-all">
          <%= @task.title %>
        </span>
      </form>
    </li>
    """
  end
end
