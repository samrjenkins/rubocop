# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This cop looks for error classes inheriting from `Exception`
      # and its standard library subclasses, excluding subclasses of
      # `StandardError`. It is configurable to suggest using either
      # `StandardError` (default) or `RuntimeError` instead.
      #
      # @safety
      #   This cop's autocorrection is unsafe because `rescue` that omit
      #   exception class handle `StandardError` and its subclasses,
      #   but not `Exception` and its subclasses.
      #
      # @example EnforcedStyle: standard_error (default)
      #   # bad
      #
      #   class C < Exception; end
      #
      #   C = Class.new(Exception)
      #
      #   # good
      #
      #   class C < StandardError; end
      #
      #   C = Class.new(StandardError)
      #
      # @example EnforcedStyle: runtime_error
      #   # bad
      #
      #   class C < Exception; end
      #
      #   C = Class.new(Exception)
      #
      #   # good
      #
      #   class C < RuntimeError; end
      #
      #   C = Class.new(RuntimeError)
      class InheritException < Base
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG = 'Inherit from `%<prefer>s` instead of `%<current>s`.'
        PREFERRED_BASE_CLASS = {
          runtime_error: 'RuntimeError',
          standard_error: 'StandardError'
        }.freeze
        ILLEGAL_CLASSES = %w[
          Exception
          SystemStackError
          NoMemoryError
          SecurityError
          NotImplementedError
          LoadError
          SyntaxError
          ScriptError
          Interrupt
          SignalException
          SystemExit
        ].freeze

        RESTRICT_ON_SEND = %i[new].freeze

        # @!method class_new_call?(node)
        def_node_matcher :class_new_call?, <<~PATTERN
          (send
            (const {cbase nil?} :Class) :new
            $(const {cbase nil?} _))
        PATTERN

        def on_class(node)
          return unless node.parent_class && illegal_class_name?(node.parent_class)

          message = message(node.parent_class)

          add_offense(node.parent_class, message: message) do |corrector|
            corrector.replace(node.parent_class, preferred_base_class)
          end
        end

        def on_send(node)
          constant = class_new_call?(node)
          return unless constant && illegal_class_name?(constant)

          message = message(constant)

          add_offense(constant, message: message) do |corrector|
            corrector.replace(constant, preferred_base_class)
          end
        end

        private

        def message(node)
          format(MSG, prefer: preferred_base_class, current: node.const_name)
        end

        def illegal_class_name?(class_node)
          ILLEGAL_CLASSES.include?(class_node.const_name)
        end

        def preferred_base_class
          PREFERRED_BASE_CLASS[style]
        end
      end
    end
  end
end
