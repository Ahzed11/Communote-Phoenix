defmodule CommunoteWeb.NoteLive.FormComponent do
  use CommunoteWeb, :live_component

  alias Communote.Notes
  alias Communote.Courses
  alias Communote.Years

  @impl true
  def mount(socket) do
    {:ok,
      socket
      |> assign(:uploaded_files, [])
      |> allow_upload(:note_file, accept: ~w(.pdf), max_entries: 1, external: &presign_upload/2)}
  end

  defp presign_upload(_entry, socket) do
    bucket = Application.fetch_env!(:communote, :bucket_name)
    key = "zizi.pdf"

    {:ok, presigned_url} = ExAws.Config.new(:s3) |> ExAws.S3.presigned_url(:put, bucket, key)
    meta = %{uploader: "S3", bucket: bucket, key: key, url: presigned_url}
    {:ok, meta, socket}
  end

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
    note = Map.put(note_params, "user_id", socket.assigns.current_user.id)
    save_note(socket, socket.assigns.action, note)
  end

  defp save_note(socket, :edit, note_params) do
    case Notes.update_note(socket.assigns.note, note_params) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_note(socket, :new, note_params) do
    consume_uploaded_entries(socket, :note_file, fn %{} = meta, _entry ->
      {:ok, presigned_url} =
        ExAws.Config.new(:s3)
        |> ExAws.S3.presigned_url(:get, meta.bucket, meta.key, expires_in: 86_400)

      presigned_url
    end)

    case Notes.create_note(note_params) do
      {:ok, note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note created successfully")
         |> push_redirect(to: Routes.note_show_path(socket, :show, note.slug))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:external_client_failure), do: "External client failure"
end
