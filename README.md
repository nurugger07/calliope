![Calliope](http://f.cl.ly/items/0T3a1a1w472z2o3p0d3O/6660441229_f6503a0dd2_b.jpg)

# Calliope - An Elixir Haml Parser [![Build Status](https://travis-ci.org/nurugger07/calliope.png?branch=master)](https://travis-ci.org/nurugger07/calliope)

For those of you that prefer the poetic beauty of [HAML](https://github.com/haml/haml) templates over HTML, then Calliope is the package for you. Calliope is a parser written in [Elixir](http://elixir-lang.org/) that will render HAML/Elixir templates into HTML. For example, we can render the following HAML:

``` haml
!!! 5
%html{lang: "en-US"}
  %head
    %title Welcome to Calliope
  %body
    %h1 Calliope
    %h2 The muse of epic poetry
```

Into this HTML:

``` html
<!DOCTYPE html>
<html lang="en-US">
  <head>
    <title>Welcome to Calliope</title>
  </head>
  <body>
    <h1>Calliope</h1>
    <h2>The muse of epic poetry</h2>
  </body>
</html>
```

## Using


Calliope is simple to add to any project. If you are using the hex package manager, just add the following to your mix file:

``` elixir
def deps do
  [ { :calliope, '~> 0.3.0' } ]
end
```

If you aren't using hex, add the reference to the github repo.

``` elixir
def deps do
  [ { :calliope, github: "nurugger07/calliope" } ]
end
```

Then run `mix deps.get` in the shell to fetch and compile the dependencies. Then you can either call to Calliope directly:

``` shell
iex(1)> Calliope.render "%h1 Welcome to Calliope"
"<h1>Welcome to Calliope</h1>"
```

Or you can `use` Calliope in a module and call through your module:

``` elixir
defmodule MyModule do
  use Calliope
end
```

``` shell
iex(1)> MyModule.render "%h1 Welcome to Calliope"
"<h1>Welcome to Calliope</h1>"
```

## Formating

If you are not familiar with HAML syntax I would suggest you checkout the [reference](http://haml.info/docs/yardoc/file.REFERENCE.html) page. Most of the syntax has been accounted for but we are in the process of adding more functionality.

HAML is basically a whitespace sensitive shorthand for HTML that does not use end-tags. Although Calliope uses HAML formating, it does use its own flavor. Sounds great but what does it look like:

``` haml
%tag{ attr: "", attr: "" } Content
```

Or you could use the following:

``` haml
%tag(attr="" attr="" ) Content
```

The `id` and `class` attributes can also be assigned directly to the tag:

``` haml
%tag#id.class Content
```

If you are creating a div you don't need to include the tag at all. This HAML

``` haml
#main
  .blue Content
```

Will generate the following HTML

``` html
<div id='main'>
  <div class='blue'>
    Content
  </div>
</div>
```

## Passing Arguments

The render function will also take a list of named arguments that can be evaluated when compiling the HTML

Given the following HAML:

``` haml
#main
  .blue= content
```

Then call render and pass in  the `haml` and `content`:

``` elixir
Calliope.render haml, [content: "Hello, World"]
```

Calliope will render:

``` html
<div id='main'>
  <div class='blue'>
    Hello, World
  </div>
</div>
```

## Embedded Elixir

Calliope doesn't just evaluate arguments, you can actually embed Elixir directly into the templates:

### for

``` haml
- for { id, headline, content } <- posts do
  %h1
    %a{href: "posts/#{id}"}= headline
  .content
    = content
```

Pass that to `render` with a list of posts

``` elixir
Calliope.render haml, [posts: [{1, "Headline 1", "Content 1"}, {2, "Headline 2", "Content 2"}]
```

Will render

``` html
<h1>
  <a href="/posts/1">Headline 1</a>
</h1>
<div class="content">
  Content 1
</div>
<h1>
  <a href="/posts/2">Headline 2</a>
</h1>
<div class="content">
  Content 2
</div>
```

### if, else, and unless

``` haml
- if post do 
  %h1= post.title
  - if post.comments do
    %p Has some comments
  - else
    %p No Comments
- unless user_guest(user)
  %a{href: "posts/edit/#{id}"}= Edit
```

### case

``` haml
- case example do
  - "one" -> 
    %p Example one
  - other -> 
    %p Other Example  
      #{other}
```

### Local Variables

``` haml
- answer = 42
%p= "What is the answer #{answer}"
```

### Anonymous Functions

``` haml
- form_for @changeset, @action, fn f ->
  .form-group
    = label f, :name, "Name", class: "control-label" 
    = text_input f, :name, class: "form-control" 
  .form-group
    = submit "Submit", class: "btn btn-primary" 
```

## Precompile Templates

Calliope provides an Engine to precompile your haml templates into functions. This parses the template at compile time and creates a function that takes the name and args needed to render the page. These functions are scoped to the module that uses the engine.

Adding this functionality is easy.

``` elixir
  defmodule Simple do

    use Calliope.Engine

    def show do
      content_for(:show, [title: Calliope])
    end

  end
```

If you are using layouts, you can set the layout and call the `content_with_layout` function.

``` elixir
  defmodule Simple do

    use Calliope.Engine, layout: "application"

    def show do
      content_with_layout(:show, [title: Calliope])
    end

  end
```

In addition to `:layout`, you can also set the following options:

`:path` - provides the root path. The default is the current working directory.
`:templates` - used to define where the templates are stored. By default it will use `:path`
`:alias` - used to set the directory where the templates are located. The
            default value is 'templates'.
`:layout_directory` - the directory that your layouts are stored relative to the
             templates path. The default directory is `layouts`
`:layout` - the layout to use for templates. The default is `:none` or you can pass in
            the name of a layout.

## Coming Soon

* Rendering partials
* Exception messages
