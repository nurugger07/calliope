defmodule Simple do
  use Calliope.Engine, [
    alias: "simple",
    templates: "test/fixtures",
    layout: :none
  ]
end

defmodule SimpleLayout do
  use Calliope.Engine, [
    alias: nil,
    templates: "test/fixtures/simple",
    layout: "application"
  ]
end

defmodule CalliopeEngineTest do
  use ExUnit.Case

  import Simple

  test :render_pages do
    assert "<h1>Calliope</h1>Index Page" == content_for :index, [title: "Calliope"]
  end

  test :content_for_multiple_views do
    assert "This is the edit page" == content_for :edit, []
    assert "This is the show page" == content_for :show, []
    assert "This is foo" == content_for :foo, []
  end
end

defmodule CalliopeEngineLayoutTest do
  use ExUnit.Case

  import SimpleLayout

  test :render_page_with_layout do
    content = "<h1>The Application Layout</h1><h1>Calliope</h1>Index Page"

    assert content == content_with_layout :index, [title: "Calliope"]
  end

end
