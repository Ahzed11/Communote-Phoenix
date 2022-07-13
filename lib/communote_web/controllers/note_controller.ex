defmodule CommunoteWeb.NoteController do
  use CommunoteWeb, :controller
  alias Communote.Notes

  def download(conn, %{"slug" => slug} = _params) do
    conn
    |> redirect(external: Notes.get_public_file_url_from_s3(slug))
  end
end
