defmodule TodosWeb.TaskLive.IndexTracker do
  def create_id_list(enum) when is_list(enum), do: Enum.map(enum, & &1.id)

  def remove_task(enum, task_id), do: List.delete(enum, task_id)

  def insert_task(enum, task_id) do
    case task_id in enum do
      true ->
        {enum, 0}

      false ->
        new_index = Enum.find_index(enum, fn id -> id < task_id end) || length(enum)
        {List.insert_at(enum, new_index, task_id), new_index}
    end
  end
end
