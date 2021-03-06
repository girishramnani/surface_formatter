defmodule Surface.Code do
  @moduledoc "Utilities for dealing with Surface code"

  @doc """
  Formats the given Surface code string. (Typically the contents of an `~H`
  sigil or `.sface` file.)

  In short:

    - HTML/Surface elements are indented to the right of their parents.
    - Attributes are split on multiple lines if the line is too long; otherwise on the same line.
    - Elixir code snippets (inside `{{ }}`) are ran through the Elixir code formatter.
    - Lack of whitespace is preserved, so that intended behaviors are not removed.
      (For example, `<span>Foo bar baz</span>` will not have newlines or spaces added.)

  Below the **Options** section is a non-exhaustive list of behaviors of the formatter.

  ## Options

    * `:line_length` - the line length to aim for when formatting
    the document. Defaults to 98. As with the Elixir formatter,
    this value is used as reference but is not always enforced
    depending on the context.

  ## Indentation

  The formatter ensures that children are indented one tab (two spaces) in from
  their parent.

  ## Whitespace

  ### Whitespace that exists

  As in regular HTML, any string of continuous whitespace is considered
  equivalent to any other string of continuous whitespace. There are three
  exceptions:

  1. Macro components (with names starting with `#`, such as `<#Markdown>`)
  2. `<pre>` tags
  3. `<code>` tags

  The contents of those tags are considered whitespace-sensitive, and developers
  should sanity check after running the formatter.

  ### Whitespace that doesn't exist (Lack of whitespace)

  As is sometimes the case in HTML, _lack_ of whitespace is considered
  significant. Instead of attempting to determine which contexts matter, the
  formatter consistently retains lack of whitespace. This means that the
  following

  ```html
  <div><p>Hello</p></div>
  ```

  will not be changed. However, the following

  ```html
  <div> <p> Hello </p> </div>
  ```

  will be formatted as

  ```html
  <div>
    <p>
      Hello
    </p>
  </div>
  ```

  because of the whitespace on either side of each tag.

  To be clear, this example

  ```html
  <div> <p>Hello</p> </div>
  ```

  will be formatted as

  ```html
  <div>
    <p>Hello</p>
  </div>
  ```

  because of the lack of whitespace in between the opening and closing `<p>` tags
  and their child content.

  ### Splitting children onto separate lines

  If there is a not a _lack_ of whitespace that needs to be respected, the
  formatter puts separate nodes (e.g. HTML elements, interpolations `{{ ... }}`,
  etc) on their own line. This means that

  ```html
  <div> <p>Hello</p> {{1 + 1}} <p>Goodbye</p> </div>
  ```

  will be formatted as

  ```html
  <div>
    <p>Hello</p>
    {{ 1 + 1 }}
    <p>Goodbye</p>
  </div>
  ```

  ### Newline characters

  The formatter will not add extra newlines unprompted beyond moving nodes onto
  their own line.  However, if the input code has extra newlines, the formatter
  will retain them but will collapse more than one extra newline into a single
  one.

  This means that

  ```html
  <section>


  Hello



  </section>
  ```

  will be formatted as

  ```html
  <section>

    Hello

  </section>
  ```

  It also means that

  ```html
  <section>
    <p>Hello</p>
    <p>and</p>





    <p>Goodbye</p>
  </section>
  ```

  will be formatted as

  ```html
  <section>
    <p>Hello</p>
    <p>and</p>

    <p>Goodbye</p>
  </section>
  ```

  ## Attributes

  HTML attributes such as `class` in `<p class="container">` are formatted to
  make use of Surface features.

  ### Inline literals

  String, integer, and boolean literals are placed after the `=` without any
  interpolation brackets (`{{ }}`). This means that

  ```html
  <Component foo={{ "hello" }} bar={{123}} secure={{   false }} />
  ```

  will be formatted as

  ```html
  <Component foo="hello" bar=123 secure=false />
  ```

  One exception is that `true` boolean literals are formatted using the Surface
  shorthand whereby you can simply write the name of the attribute and it is
  passed in as `true`.  For example,

  ```html
  <Component secure={{ true }} />
  ```

  and

  ```html
  <Component secure=true />
  ```

  will both be formatted as

  ```html
  <Component secure />
  ```

  ### Interpolation (`{{ }}` brackets)

  Attributes that interpolate Elixir code with `{{ }}` brackets are ran through
  the Elixir code formatter.

  This means that:

    - `<Foo num=123456 />` becomes `<Foo num=123_456 />`
    - `list={{[1,2,3]}}` becomes `list={{ [1, 2, 3] }}`
    - `things={{  %{one: "1", two: "2"}}}` becomes `things={{ %{ one: "1", two: "2" } }}`

  Sometimes the Elixir code formatter will add line breaks in the formatted
  expression. In that case, SurfaceFormatter will ensure indentation lines up. If
  there is a single attribute, it will keep the attribute on the same line as the
  tag name, for example:

  ```html
  <Component list={{[
    {"foo", foo},
    {"bar", bar}
  ]}} />
  ```

  However, if there are multiple attributes it will put them on separate lines:

  ```html
  <Child
    list={{[
      {"foo", foo},
      {"bar", bar}
    ]}}
    int=123
  />
  ```

  Note in the above example that if the Elixir code formatter introduces
  newlines, whitespace between the expression and the interpolation brackets is
  collapsed.  That is to say the formatter will emit `list={{[` instead of
  `list={{ [`.

  ### Wrapping attributes on separate lines

  In the **Interpolation (`{{ }}` brackets)** section we noted that attributes
  will each be put on their own line if there is more than one attribute and at
  least one contains a newline after being formatted by the Elixir code
  formatter.

  There is another scenario where attributes will each be given their own line:
  **any time the opening tag would exceed `line_length` if put on one line**.
  This value is provided in `.formatter.exs` and defaults to 98.

  The formatter indents attributes one tab in from the start of the opening tag
  for readability:

  ```html
  <div
    class="very long class value that causes this to exceed the established line length"
    aria-role="button"
  >
  ```

  If you desire to have a separate line length for `mix format` and `mix surface.format`,
  provide `surface_line_length` in `.formatter.exs` and it will be given precedence
  when running `mix surface.format`. For example:

  ```elixir
  # .formatter.exs

  [
    surface_line_length: 120,
    import_deps: [...],
    # ...
  ]
  ```

  ### HTML Comments

  The formatter removes HTML comments. This is because the Surface parser
  (which SurfaceFormatter uses under the hood) does not expose them.

  This means

  ```html
  <div>
    <!-- Some comment -->
    <p>Hello</p>
  </div>
  ```

  becomes

  ```html
  <div>
    <p>Hello</p>
  </div>
  ```

  It is recommended to use an interpolated Elixir comment instead:

  ```html
  <div>
    {{ # Some comment }}
    <p>Hello</p>
  </div>
  ```

  As with all changes (for both `mix format` and `mix surface.format`) it's
  recommended that developers don't blindly run the formatter on an entire
  codebase and commit, but instead sanity check each file to ensure the results
  are desired.

  """
  @spec format_string!(String.t(), list(Surface.Code.Formatter.option())) :: String.t()
  def format_string!(string, opts \\ []) do
    string
    |> Surface.Code.Formatter.parse()
    |> Surface.Code.Formatter.format(opts)
  end
end
