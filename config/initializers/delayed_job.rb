# frozen_string_literal: true

# Delayed::Worker.queue_attributes = {
#   default: { priority: 10 },
#   events: { priority: 0 },
#   import: { priority: 20}
# }
Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_run_time = 4.hours
Delayed::Worker.default_queue_name = :default
Delayed::Worker.raise_signal_exceptions = :term
Delayed::Worker.logger = Rails.logger
Delayed::Worker.max_attempts = if ENV['RAILS_ENV'] == 'development'
                                 3
                               else
                                 15
                               end

# OVERRIDE: for ruby 3 support - https://github.com/collectiveidea/delayed_job/pull/1158
# module Delayed
#   class PerformableMethod
#     # serialize to YAML
#     def encode_with(coder)
#       coder.map = {
#         'object' => object,
#         'method_name' => method_name,
#         'args' => args,
#         'kwargs' => kwargs
#       }
#     end
#   end

#   class PerformableMethod
#     attr_accessor :object, :method_name, :args, :kwargs

#     def initialize(object, method_name, args, kwargs = {})
#       raise NoMethodError, "undefined method `#{method_name}' for #{object.inspect}" unless object.respond_to?(method_name, true)

#       if object.respond_to?(:persisted?) && !object.persisted?
#         raise(ArgumentError, "job cannot be created for non-persisted record: #{object.inspect}")
#       end

#       self.object       = object
#       self.args         = args
#       self.kwargs       = kwargs
#       self.method_name  = method_name.to_sym
#     end

#     def display_name
#       if object.is_a?(Class)
#         "#{object}.#{method_name}"
#       else
#         "#{object.class}##{method_name}"
#       end
#     end

#     def kwargs
#       # Default to a hash so that we can handle deserializing jobs that were
#       # created before kwargs was available.
#       @kwargs || {}
#     end

#     # In ruby 3 we need to explicitly separate regular args from the keyword-args.
#     if RUBY_VERSION >= '3.0'
#       def perform
#         object.send(method_name, *args, **kwargs) if object
#       end
#     else
#       # On ruby 2, rely on the implicit conversion from a hash to kwargs
#       def perform
#         return unless object
#         if kwargs.present?
#           object.send(method_name, *args, kwargs)
#         else
#           object.send(method_name, *args)
#         end
#       end
#     end

#     def method(sym)
#       object.method(sym)
#     end
#     method_def = []
#     location = caller_locations(1, 1).first
#     file = location.path
#     line = location.lineno
#     definition = RUBY_VERSION >= '2.7' ? '...' : '*args, &block'
#     method_def <<
#       "def method_missing(#{definition})" \
#       "  object.send(#{definition})" \
#       'end'
#     module_eval(method_def.join(';'), file, line)

#     def respond_to?(symbol, include_private = false)
#       super || object.respond_to?(symbol, include_private)
#     end
#   end

#   class PerformableMailer < PerformableMethod
#     def perform
#       mailer = super
#       mailer.respond_to?(:deliver_now) ? mailer.deliver_now : mailer.deliver
#     end
#   end

#   class DelayProxy < Delayed::Compatibility.proxy_object_class
#     def initialize(payload_class, target, options)
#       @payload_class = payload_class
#       @target = target
#       @options = options
#     end

#     # rubocop:disable MethodMissing
#     def method_missing(method, *args, **kwargs)
#       Job.enqueue({:payload_object => @payload_class.new(@target, method.to_sym, args, kwargs)}.merge(@options))
#     end
#     # rubocop:enable MethodMissing
#   end
# end
