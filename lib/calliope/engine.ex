defmodule Calliope.Engine do

  import Calliope.Render

  @doc """
  The Calliope Engine allows you to precompile your haml templates to be accessed
  through functions at runtime.

  Example:

  defmodule Simple do

    use Calliope.Engine

    def show do
      content_for(:show, [title: Calliope])
    end

  end

  The configure options are:

  `:path` - provides the root path. The default is the current working directory.
  `:templates` - used to define where the templates are stored.
  `:alias` - used to set the directory where the templates are located. The
             default value is 'templates'.
  `:layout` - the layout to use for templates. The default is `:none` or you can pass in
             the name of a layout.
  `:layout_directory` - the directory that your layouts are stored relative to the
             templates path. The default directory is `layouts`

  """

  defmacro __using__(opts \\ []) do
    dir = Keyword.get(opts, :alias, "templates")
    templates = Keyword.get(opts, :templates, nil)
    root = Keyword.get(opts, :path, File.cwd!)
    layout = Keyword.get(opts, :layout, :none)
    layout_directory = Keyword.get(opts, :layout_directory, "layouts")

    path = build_path_for [root, templates, dir]
    layout_path = build_path_for [root, templates, layout_directory]

    quote do
      import unquote(__MODULE__)

      use Calliope.Render

      compile_layout unquote(layout), unquote(layout_path)

      compile_templates unquote(path)

      def layout_for(content, args\\[]) do
        content_for unquote(layout), [ yield: content ] ++ args
      end

      def content_with_layout(name, args) do
        content_for(name, args) |> layout_for(args)
      end

      def content_for(:none, args) do
        Keyword.get(args, :yield, "") |> Calliope.Render.eval(args)
      end
    end
  end

  defmacro compile_layout(:none, _path), do: nil
  defmacro compile_layout(_layout, path) do
    quote do
      compile_templates unquote(path)
    end
  end

  defmacro compile_templates(path) do
    path = eval_path(path)
    quote do: unquote files_for(path) |> haml_views |> view_to_function(path)
  end

  def build_path_for(list), do: Enum.filter(list, fn(x) -> is_binary x end) |> Enum.join("/")

  def eval_path(path) do
    { path, _ } = Code.eval_quoted path
    path
  end

  def files_for(nil), do: []
  def files_for(path), do: File.ls! path

  def haml_views(files) do
    Enum.filter(files, fn(v) -> Regex.match?(~r{^\w*\.html\.haml$}, v) end)
  end

  def precompile_view(path), do: File.read!(path) |> precompile

  def view_to_function([], _), do: ""
  def view_to_function([view|t], path) do
    [ name, _, _ ] = String.split(view, ".")

    content = precompile_view path <> "/" <> view

    quote do
      def content_for(unquote(String.to_atom name), args) do
        Calliope.Render.eval unquote(content), args
      end
      def content_for(unquote(name), args) do
        Calliope.Render.eval unquote(content), args
      end

      unquote(view_to_function(t, path))
    end
  end

end
