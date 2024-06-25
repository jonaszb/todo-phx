defmodule TodosWeb.TaskLive.Index do
  @known_filters ["Active", "All", "Completed"]
  use TodosWeb, :live_view

  alias Todos.Tasks
  alias Todos.Tasks.Task

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe()
    end

    tasks = Tasks.list_tasks()
    {:ok, default_filter} = Enum.fetch(@known_filters, 0)

    {:ok,
     socket
     |> stream(:tasks, tasks)
     |> assign(
       form: Tasks.change_task(%Task{}) |> to_form,
       filter: default_filter,
       count: length(Enum.filter(tasks, fn %{done: done} -> done == false end))
     )}
  end

  def dark_mode_toggle(assigns) do
    ~H"""
    <button phx-click={JS.dispatch("toggle-darkmode")}>
      <.icon name="hero-moon-solid" class="bg-white dark:hidden" />
      <.icon name="hero-sun-solid" , class="bg-white hidden dark:block" />
    </button>
    """
  end

  def handle_info({:task_created, task}, socket) do
    socket = update(socket, :count, &(&1 + 1))
    {:noreply, stream_insert(socket, :tasks, task, at: 0)}
  end

  def handle_info({:task_updated, task}, socket) do
    socket =
      case task.done do
        true -> update(socket, :count, &(&1 - 1))
        false -> update(socket, :count, &(&1 + 1))
      end

    {:noreply, stream_insert(socket, :tasks, task)}
  end

  def handle_info({:task_deleted, task}, socket) do
    socket =
      case task.done do
        true -> socket
        false -> update(socket, :count, &(&1 - 1))
      end

    {:noreply, stream_delete(socket, :tasks, task)}
  end

  # @impl true
  # def handle_info({TodosWeb.TaskLive.FormComponent, {:saved, task}}, socket) do
  #   {:noreply, stream_insert(socket, :tasks, task)}
  # end

  @impl true
  def handle_event("validate", task_params, socket) do
    changeset = %Task{} |> Tasks.change_task(task_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    socket =
      if(filter in @known_filters) do
        assign(socket, :filter, filter)
      else
        socket
      end

    {:noreply, stream}
  end

  # @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)
    {:noreply, socket}
  end

  def handle_event("create_task", params, socket) do
    {:ok, _new_task} = Tasks.create_task(params)

    {:noreply,
     socket
     |> assign(form: Tasks.change_task(%Task{}) |> to_form)}
  end

  def handle_event("toggle_status", %{"id" => id} = params, socket) do
    task = Tasks.get_task!(id)

    new_status =
      case params do
        %{"status" => "on"} -> true
        _ -> false
      end

    {:ok, _task} = Tasks.update_task(task, %{done: new_status})
    {:noreply, socket}
  end

  defp should_render(task, filter) do
    case filter do
      "All" -> true
      "Active" -> task.done == false
      "Completed" -> task.done == true
    end
  end

  def new_task_form(assigns) do
    ~H"""
    <.form
      class="mt-6 bg-white dark:bg-[#25273D] px-6 py-5 rounded-md flex gap-6 drop-shadow-3xl z-10"
      phx-submit="create_task"
      phx-change="validate"
      phx-debounce="1000"
      for={@form}
    >
      <div class="border-[#E3E4F1] dark:border-[#393A4B] rounded-full border w-6 h-6" />
      <input
        name="title"
        placeholder="Create a new todo..."
        class="text-lg outline-none placeholder-[#9495A5] dark:placeholder-[#767992] text-[#494C6B] dark:text-[#C8CBE7] w-full bg-transparent dark:caret-slate-50"
      />
      <label for="title" class="hidden">Create a new todo</label>
    </.form>
    """
  end

  def todo_item(assigns) do
    ~H"""
    <li
      class="group px-6 py-5 flex justify-between border-b border-[#E3E4F1] dark:border-[#393A4B]"
      id={@id}
    >
      <.form for={to_form(Tasks.change_task(@task))} class="flex gap-6" phx-value-id={@task.id}>
        <label
          for={@task.id |> Integer.to_string()}
          class="border-[#E3E4F1] dark:border-[#393A4B] rounded-full peer border w-6 h-6 flex justify-center cursor-pointer items-center has-[:checked]:bg-gradient-to-br has-[:checked]:from-[#55DDFF] has-[:checked]:to-[#C058F3]"
        >
          <input
            phx-change="toggle_status"
            type="checkbox"
            checked={@task.done}
            class="hidden peer"
            name="status"
            id={@task.id |> Integer.to_string()}
          />
          <.icon name="hero-check-micro" class="bg-white hidden peer-checked:block" />
        </label>
        <span class="text-lg text-[#494C6B] dark:text-[#C8CBE7] peer-has-[:checked]:text-[#D1D2DA] dark:peer-has-[:checked]:text-[#4D5067] peer-has-[:checked]:line-through transition-all">
          <%= @task.title %>
        </span>
      </.form>
      <button
        phx-click="delete"
        phx-value-id={@task.id}
        data-confirm="Are you sure?"
        class="hidden transition-all group-hover:block text-[#D1D2DA] dark:text-[#494C6B]  hover:text-white relative group/delete px-2 translate-x-2"
      >
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-red-500 opacity-75  scale-0 group-hover/delete:scale-100 transition-all" />
        <.icon name="hero-trash-solid" class="w-5" />
      </button>
    </li>
    """
  end
end