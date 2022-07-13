defmodule Communote.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Communote.Repo

  alias Communote.Notes.Note

  @doc """
  Gets the number of notes.

  ## Examples

      iex> get_note_count()
      10

  """
  def get_note_count() do
    query = from n in Note, select: count()
    Repo.one(query)
  end

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes()
      [%Note{}, ...]

  """
  def list_notes do
    Repo.all(Note)
  end

  @doc """
  Gets all notes by searching the slug.
  ## Examples
      iex> list_notes_by_slug("a-nice-title")
      [%Note{}, ...]
  """
  def list_notes_by_slug(slug) do
    query = from n in Note,
            where: n.slug == ^slug
    Repo.all(query)
  end

  @doc """
  Gets all notes by searching the user_id.
  ## Examples
      iex> list_notes_by_user_id(1)
      [%Note{}, ...]
  """
  def list_notes_by_user_id(user_id) do
    query = from n in Note,
            join: y in assoc(n, :year),
            join: c in assoc(n, :course),
            where: n.user_id == ^user_id,
            preload: [:user, year: y, course: c],
            order_by: [desc: y.year]
    Repo.all(query)
  end


  @doc """
  Returns the list of notes for a given course code.
  ## Examples
      iex> list_notes_by_course_code("LINFO1104")
      [%Note{}, ...]
  """
  def list_notes_by_course_code(course_code) do
    query = from n in Note,
            join: y in assoc(n, :year),
            join: c in assoc(n, :course),
            where: c.code == ^course_code,
            preload: [:user, year: y, course: c],
            order_by: [desc: y.year]

    Repo.all(query)
  end


  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id), do: Repo.get!(Note, id)

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note_by_slug!("some-slug")
      %Note{}

      iex> get_note_by_slug!("some-slug")
      ** (Ecto.NoResultsError)

  """
  def get_note_by_slug(slug) do
    query = from n in Note,
            where: n.slug == ^slug,
            preload: [:user, :year, :course]
    Repo.one!(query)
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(attrs \\ %{}) do
    %Note{}
    |> Note.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(note)
      {:ok, %Note{}}

      iex> delete_note(note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Note{} = note) do
    Repo.delete(note)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{data: %Note{}}

  """
  def change_note(%Note{} = note, attrs \\ %{}) do
    Note.changeset(note, attrs)
  end

  def get_public_file_url_from_s3(slug) do
    "#{get_public_file_base_url_with_bucket()}#{slug}.pdf"
  end

  defp get_public_file_base_url_with_bucket() do
    base_url = Application.fetch_env!(:communote, :public_files_base_url)
    bucket = Application.fetch_env!(:communote, :bucket_name)
    "#{base_url}/#{bucket}/"
  end

  def delete_file_from_s3(slug) do
    :communote
    |> Application.fetch_env!(:bucket_name)
    |> ExAws.S3.delete_object("#{slug}.pdf")
    |> ExAws.request()
  end
end
