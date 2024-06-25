# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:

alias Todos.Tasks
#
Todos.Repo.insert!(%Tasks.Task{
  title: "Get milk",
  done: true
})

Todos.Repo.insert!(%Tasks.Task{
  title: "Go for a walk",
  done: false
})

Todos.Repo.insert!(%Tasks.Task{
  title: "Clean the house",
  done: true
})

#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
