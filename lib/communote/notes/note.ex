defmodule Communote.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset
  alias Communote.Accounts.User
  alias Communote.Courses.Course
  alias Communote.Years.Year
  alias Communote.Notes
  alias Communote.Slug

  schema "notes" do
    field :description, :string
    field :slug, :string
    field :small_description, :string
    field :title, :string
    field :course_search, :string, virtual: true
    belongs_to(:user, User)
    belongs_to(:course, Course)
    belongs_to(:year, Year)

    timestamps()
  end

  @doc false
  def changeset(note, attrs) do
    note
    |> cast(attrs, [:title, :description, :small_description, :user_id, :course_id, :year_id, :course_search])
    |> validate_required([:title, :description, :small_description, :user_id, :course_id, :year_id])
    |> generate_slug()
    |> unique_constraint(:slug)
  end

  def generate_slug(changeset) do
    title = get_field(changeset, :title)
    Slug.generate_slug(changeset, title, &Notes.list_notes_by_slug/1, &Notes.get_note!/1)
  end

end
