defmodule TodosWeb.TaskLive.Index do
  @known_filters ["All", "Active", "Completed"]
  use TodosWeb, :live_view

  alias Todos.Tasks
  alias Todos.Tasks.Task
  alias TodosWeb.TaskLive.IndexTracker

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Tasks.subscribe()
    end

    {:ok, default_filter} = Enum.fetch(@known_filters, 0)
    tasks = list_tasks_with_filter(default_filter)
    count = Tasks.count_tasks()
    id_map = IndexTracker.create_id_list(tasks)
    changeset = %Task{} |> Tasks.change_task() |> Map.put(:action, :validate)

    {:ok,
     socket
     |> stream(:tasks, tasks)
     |> assign(
       id_map: id_map,
       form: to_form(changeset),
       filter: default_filter,
       count: count,
       clearing: false
     )}
  end

  def list_tasks_with_filter(filter) do
    case filter do
      "All" -> Tasks.list_tasks()
      "Active" -> Tasks.list_tasks(%{done: false})
      "Completed" -> Tasks.list_tasks(%{done: true})
    end
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

    socket =
      if should_render?(socket, task) do
        insert_task(socket, task)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_info({:task_updated, task}, socket) do
    socket =
      case task.done do
        true -> update(socket, :count, &(&1 - 1))
        false -> update(socket, :count, &(&1 + 1))
      end

    socket =
      if should_render?(socket, task) do
        insert_task(socket, task)
      else
        delete_task(socket, task)
      end

    {:noreply, socket}
  end

  def handle_info({:task_deleted, task}, socket) do
    socket =
      case task.done do
        true -> socket
        false -> update(socket, :count, &(&1 - 1))
      end

    {:noreply,
     assign(socket,
       id_map:
         case should_render?(socket, task) do
           true -> IndexTracker.remove_task(socket.assigns.id_map, task.id)
           false -> socket.assigns.id_map
         end
     )
     |> stream_delete(:tasks, task)}
  end

  def handle_info({:done_tasks_deleted, count}, socket) do
    socket = put_flash(socket, :info, "Cleared #{count} completed task#{if count > 1, do: "s"}")
    tasks = list_tasks_with_filter(socket.assigns.filter)

    {:noreply,
     socket
     |> stream(:tasks, tasks, reset: true)
     |> assign(id_map: IndexTracker.create_id_list(tasks), clearing: false)}
  end

  @impl true
  def handle_event("validate", task_params, socket) do
    changeset = %Task{} |> Tasks.change_task(task_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("filter", %{"filter" => filter}, socket) do
    socket = if filter in @known_filters, do: assign(socket, :filter, filter), else: socket
    tasks = list_tasks_with_filter(socket.assigns.filter)

    {:noreply,
     assign(socket, id_map: IndexTracker.create_id_list(tasks))
     |> stream(:tasks, tasks, reset: true)}
  end

  # @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)
    {:noreply, socket}
  end

  def handle_event("create_task", params, %{assigns: %{form: %{errors: []}}} = socket) do
    socket =
      case Tasks.create_task(params) do
        {:ok, _new_task} -> assign(socket, form: Tasks.change_task(%Task{}) |> to_form)
        {:error, error_msg} -> put_flash(socket, :error, error_msg)
      end

    {:noreply, socket}
  end

  def handle_event("create_task", _params, %{assigns: %{form: %{errors: errors}}} = socket) do
    [title: {msg, _}] = errors
    {:noreply, put_flash(socket, :error, msg)}
  end

  def handle_event("clear_completed", _, socket) do
    socket =
      case Tasks.delete_done_tasks() do
        {:ok, _} -> assign(socket, clearing: true)
        _ -> socket
      end

    {:noreply, socket}
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

  defp insert_task(socket, task) do
    {id_map, new_index} = IndexTracker.insert_task(socket.assigns.id_map, task.id)
    assign(socket, id_map: id_map) |> stream_insert(:tasks, task, at: new_index)
  end

  defp delete_task(socket, task) do
    assign(socket,
      id_map:
        if should_render?(socket, task) do
          socket.assigns.id_map
        else
          IndexTracker.remove_task(socket.assigns.id_map, task.id)
        end
    )
    |> stream_delete(:tasks, task)
  end

  defp should_render?(socket, task) do
    case {socket.assigns.filter, task.done} do
      {"All", _} -> true
      {"Active", false} -> true
      {"Completed", true} -> true
      _ -> false
    end
  end

  def new_task_form(assigns) do
    ~H"""
    <.form
      class="mt-4 sm:mt-6 bg-white dark:bg-[#25273D] px-5 py-4 sm:px-6 sm:py-5 rounded-md flex gap-3 sm:gap-6 drop-shadow-3xl z-10"
      phx-submit="create_task"
      phx-change="validate"
      phx-debounce="1000"
      for={@form}
    >
      <div class="border-[#E3E4F1] dark:border-[#393A4B] rounded-full border min-w-5 w-5 h-5 sm:w-6 sm:h-6" />
      <input
        name="title"
        placeholder="Create a new todo..."
        class={[
          "text-sm sm:text-lg outline-none placeholder-[#9495A5] dark:placeholder-[#767992] text-[#494C6B] dark:text-[#C8CBE7] w-full bg-transparent caret-[#3A7CFD]"
        ]}
      />
      <label for="title" class="hidden">Create a new todo</label>
    </.form>
    """
  end

  def todo_item(assigns) do
    ~H"""
    <li
      class="group px-5 sm:px-6 py-4 sm:py-5 flex items-center justify-between border-b border-[#E3E4F1] dark:border-[#393A4B]"
      id={@id}
    >
      <.form
        for={to_form(Tasks.change_task(@task))}
        class="flex gap-3 sm:gap-6 items-center"
        phx-value-id={@task.id}
      >
        <label
          for={@task.id |> Integer.to_string()}
          class="border-[#E3E4F1] dark:border-[#393A4B] rounded-full peer border w-5 sm:w-6 h-5 sm:h-6 flex justify-center cursor-pointer items-center has-[:checked]:bg-gradient-to-br has-[:checked]:from-[#55DDFF] has-[:checked]:to-[#C058F3]"
        >
          <input
            phx-change="toggle_status"
            type="checkbox"
            checked={@task.done}
            class="hidden peer"
            name="status"
            id={@task.id |> Integer.to_string()}
          />
          <.icon
            name="hero-check-micro"
            class="bg-white hidden peer-checked:block w-3 h-3 sm:w-4 sm:h-4"
          />
        </label>
        <span class="text-xs sm:text-lg text-[#494C6B] dark:text-[#C8CBE7] peer-has-[:checked]:text-[#D1D2DA] dark:peer-has-[:checked]:text-[#4D5067] peer-has-[:checked]:line-through transition-all">
          <%= @task.title %>
        </span>
      </.form>
      <button
        phx-click="delete"
        phx-value-id={@task.id}
        data-confirm="Are you sure?"
        class="sm:hidden transition-all group-hover:block   hover:text-white group/delete px-2 translate-x-2 h-4"
      >
        <svg
          class="fill-[#494C6B] sm:w-4 sm:h-4"
          width="12"
          height="12"
          viewBox="0 0 12 12"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            fill-rule="evenodd"
            clip-rule="evenodd"
            d="M11.7851 0.471404L11.3137 0L5.89256 5.42115L0.471404 0L0 0.471404L5.42115 5.89256L0 11.3137L0.471404 11.7851L5.89256 6.36396L11.3137 11.7851L11.7851 11.3137L6.36396 5.89256L11.7851 0.471404Z"
          />
        </svg>

        <%!-- <.icon name="hero-x-mark-solid" class="w-4 h-4 sm:w-5 sm:h-5" /> --%>
      </button>
    </li>
    """
  end

  def filters(assigns) do
    ~H"""
    <form phx-change="filter" class={["flex gap-4 font-bold", @class]}>
      <%= for filter <- ["All", "Active", "Completed"] do %>
        <span>
          <input
            type="radio"
            name="filter"
            value={filter}
            id={filter}
            checked={@filter == filter}
            class="hidden peer"
          />
          <label
            for={filter}
            class={[
              "cursor-pointer transition-all peer-checked:text-[#3A7CFD]",
              @filter != filter && "hover:text-[#494C6B] dark:hover:text-[#E3E4F1]"
            ]}
          >
            <%= filter %>
          </label>
        </span>
      <% end %>
    </form>
    """
  end
end
