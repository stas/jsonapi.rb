require 'ransack'

Ransack.configure do |config|
  # Raise errors if a query contains an unknown predicate or attribute.
  # Default is true (do not raise error on unknown conditions).
  config.ignore_unknown_conditions = true

  # Enable expressions
  # See: https://www.rubydoc.info/github/rails/rails/Arel/Expressions
  config.add_predicate(
    'count', arel_predicate: 'count',
    validator: ->(_) { true }, compounds: false
  )
  config.add_predicate(
    'count_distinct', arel_predicate: 'count',
    validator: ->(_) { true }, formatter: ->(_) { true }, compounds: false
  )
  config.add_predicate(
    'sum', arel_predicate: 'sum',
    validator: ->(v) { true }, compounds: false
  )
  config.add_predicate(
    'avg', arel_predicate: 'average',
    validator: ->(v) { true }, compounds: false
  )
  config.add_predicate(
    'min', arel_predicate: 'minimum',
    validator: ->(v) { true }, compounds: false
  )
  config.add_predicate(
    'max', arel_predicate: 'maximum',
    validator: ->(v) { true }, compounds: false
  )
end

Ransack::Visitor.class_eval do
  alias_method :original_visit_Ransack_Nodes_Sort, :visit_Ransack_Nodes_Sort

  private
  # Original method assumes sorting is done only by attributes
  def visit_Ransack_Nodes_Sort(node)
    # Try the default sorting visitor method...
    binded = original_visit_Ransack_Nodes_Sort(node)
    valid = (binded.valid? if binded.respond_to?(:valid?)) || true
    return binded if binded.present? && valid

    # Fallback to support the expressions...
    binded = Ransack::Nodes::Condition.extract(node.context, node.name, nil)
    valid = (binded.valid? if binded.respond_to?(:valid?)) || true
    return unless binded.present? && valid

    arel_pred = binded.arel_predicate
    # Remove any alias when sorting...
    arel_pred.alias = nil if arel_pred.respond_to?(:alias=)
    arel_pred.public_send(node.dir)
  end
end

Ransack::Nodes::Condition.class_eval do
  alias_method :original_format_predicate, :format_predicate

  private
  # Original method doesn't respect the arity of expressions
  # See: lib/ransack/adapters/active_record/ransack/nodes/condition.rb#L30-L42
  def format_predicate(attribute)
    original_format_predicate(attribute)
  rescue ArgumentError
    arel_pred = arel_predicate_for_attribute(attribute)
    attribute.attr.public_send(arel_pred)
  end
end
