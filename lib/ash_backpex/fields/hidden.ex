defmodule AshBackpex.Fields.Hidden do
  @moduledoc """
  Provides helper functions for rendering fields as hidden inputs.

  This module is used internally by ash_backpex to render fields with `hidden: true`
  as hidden HTML inputs. Hidden fields are included in form submissions but are not
  visible to or editable by users.

  ## Usage

  In your ash_backpex LiveResource, you can mark a field as hidden:

      backpex do
        resource MyApp.Blog.Post

        fields do
          field :author_id do
            hidden true
          end
        end
      end

  The field will be rendered as a hidden input and its value will be submitted with the form,
  but the user won't see or be able to modify it.
  """

  use BackpexWeb, :html

  @doc """
  Renders a field as a hidden input.

  This function is used as the `render_form` callback for fields with `hidden: true`.
  It renders the field's current value as a hidden HTML input element.

  For BelongsTo relationships, uses the `owner_key` (foreign key attribute) instead of
  the relationship name to ensure the correct field is submitted.
  """
  def render_form(assigns) do
    # For BelongsTo fields, use owner_key (e.g., :workspace_id) instead of name (e.g., :workspace)
    field_key = Map.get(assigns, :owner_key, assigns.name)

    # Get the form field - it might be under the owner_key or we need to construct the name
    form_field = assigns.form[field_key]

    # Build the input name and get value
    # For BelongsTo, the form field might not exist directly, so we construct the name
    {input_name, input_value} =
      if form_field do
        {form_field.name, form_field.value}
      else
        # Fallback: construct name from form and field_key
        # The form is namespaced as "change", so input name should be "change[workspace_id]"
        name = "#{assigns.form.name}[#{field_key}]"
        # Try to get value from the item's attribute
        value = get_in(assigns, [:item, Access.key(field_key)])
        {name, value}
      end

    assigns =
      assigns
      |> assign(:input_name, input_name)
      |> assign(:input_value, input_value)

    ~H"""
    <input type="hidden" name={@input_name} value={@input_value} />
    """
  end

  @doc """
  Checks if a field should be rendered as hidden.

  Returns `true` if the field has `hidden: true` or if `hidden` is a function
  that returns `true` when called with the assigns.
  """
  def hidden?(%{hidden: hidden}, _assigns) when is_boolean(hidden), do: hidden
  def hidden?(%{hidden: hidden}, assigns) when is_function(hidden, 1), do: hidden.(assigns)
  def hidden?(_field_options, _assigns), do: false
end
