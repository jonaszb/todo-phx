defmodule TodosWeb.TaskLiveTest do
  use TodosWeb.ConnCase

  import Phoenix.LiveViewTest
  import Todos.TasksFixtures

  @create_attrs %{title: "some title"}
  @update_attrs %{done: false, title: "some updated title"}
  @invalid_attrs %{title: nil}

  defp create_task(_) do
    task = task_fixture()
    %{task: task}
  end

  describe "Index" do
    setup [:create_task]

    test "lists all tasks", %{conn: conn, task: task} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "TODO"
      assert html =~ task.title
    end

    test "saves new task", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert index_live
             |> form("#task-form", task: @invalid_attrs)
             |> render_submit() =~ "Title cannot be empty"

      assert index_live
             |> form("#task-form", task: @create_attrs)
             |> render_submit()

      html = render(index_live)
      assert html =~ "some title"
    end

    test "updates task status", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert index_live
             |> element("#tasks-#{task.id} input")
             |> render_change(%{"id" => task.id, "status" => "on"})

      assert index_live |> has_element?("#tasks-#{task.id} input[checked]")

      assert index_live
             |> element("#tasks-#{task.id} input")
             |> render_change(%{"id" => task.id, "status" => "off"})

      refute index_live |> has_element?("#tasks-#{task.id} input[checked]")
    end

    test "deletes task in listing", %{conn: conn, task: task} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert index_live |> element("#tasks-#{task.id} button") |> render_click()
      refute has_element?(index_live, "#tasks-#{task.id}")
    end
  end
end
