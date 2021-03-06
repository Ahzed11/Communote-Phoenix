defmodule CommunoteWeb.NoteLive.FormComponent do
  use CommunoteWeb, :live_component

  alias Communote.Notes
  alias Communote.Courses
  alias Communote.Years
  alias Communote.Accounts

  @impl true
  def update(%{note: note} = assigns, socket) do
    changeset = Notes.change_note(note)
    years = Years.list_years() |> Years.enumerate()
    courses = if assigns.note.course_id do
      [Courses.get_course!(assigns.note.course_id)] |> Courses.enumerate()
    else
      []
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:courses, courses)
     |> assign(:years, years)
    }
  end

  @impl true
  def handle_event("validate", %{"note" => note_params}, socket) do
    courses = if note_params["course_search"] != "" do
     Courses.list_courses_with_fts(note_params["course_search"]) |> Courses.enumerate()
    else
      if socket.assigns.note.course_id do
        [Courses.get_course!(socket.assigns.note.course_id)] |> Courses.enumerate()
      else
        []
      end
    end

    changeset =
      socket.assigns.note
      |> Notes.change_note(note_params)
      |> Map.put(:action, :validate)

    {:noreply,
      socket
      |> assign(:changeset, changeset)
      |> assign(:courses, courses)
    }
  end

  def handle_event("save", %{"note" => note_params}, socket) do
    save_note(socket, socket.assigns.action, note_params)
  end

  defp save_note(socket, :edit, note_params) do
    case Accounts.owns?(socket.assigns.current_user, note_params) do
      true ->
        case Notes.update_note(socket.assigns.note, note_params) do
          {:ok, _note} ->
            {:noreply,
            socket
            |> put_flash(:info, "Note updated successfully")
            |> push_redirect(to: socket.assigns.return_to)}

          {:error, %Ecto.Changeset{} = changeset} -> {:noreply, assign(socket, :changeset, changeset)}
        end
      false ->
        {:noreply,
        socket
        |> put_flash(:danger, "You do not own this resource")
        |> push_redirect(to: socket.assigns.return_to)}
    end
  end

  defp save_note(socket, :new, note_params) do
    note = Map.put(note_params, "user_id", socket.assigns.current_user.id)
    case Notes.create_note(note) do
      {:ok, note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note created successfully")
         |> push_redirect(to: Routes.note_show_path(socket, :show, note.slug))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
