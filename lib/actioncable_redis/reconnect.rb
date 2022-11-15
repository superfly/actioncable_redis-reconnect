# frozen_string_literal: true

require_relative "reconnect/version"

module ActioncableRedis
  module Reconnect
    class Error < StandardError; end
  end
end

# Restart Action Cable server on Redis connection failures.
# See: https://github.com/rails/rails/pull/45478
require 'action_cable/subscription_adapter/redis'

module ActionCableRedisListenerPatch
  private

  def ensure_listener_running
    @thread ||= Thread.new do
      Thread.current.abort_on_exception = true
      conn = @adapter.redis_connection_for_subscriptions
      listen conn
    rescue ::Redis::BaseConnectionError
      @thread = @raw_client = nil
      ::ActionCable.server.restart
    end
  end
end

warn "Patching ActionCable::SubscriptionAdapter::Redis::Listener from #{__FILE__}"
ActionCable::SubscriptionAdapter::Redis::Listener.prepend(ActionCableRedisListenerPatch)
