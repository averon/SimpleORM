require_relative '03_associatable'

# Phase V
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method(name) do
      source_options = 
        through_options.model_class.assoc_options[source_name]

      primary_key = source_options.primary_key
      foreign_key_value =
        attributes[through_options.foreign_key]

      source_options
        .model_class
        .where(primary_key => foreign_key_value)
        .first
    end
  end
end
