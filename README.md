![Calliope](http://f.cl.ly/items/0T3a1a1w472z2o3p0d3O/6660441229_f6503a0dd2_b.jpg)

# Calliope - An Elixir Haml Parser

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
  [ { :calliope, '~> 0.2.1' } ]
end
```

If you aren't using hex, add the a reference to the github repo.

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

``` haml
- lc { id, headline, content } inlist posts do
  %h1
    %a{href: "posts/#{id}"= headline
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

## Coming Soon

* Rendering Elixir conditionals
* Rendering partials
* Exception messages
