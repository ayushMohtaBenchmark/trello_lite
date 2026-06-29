# Use Oj for fast JSON encoding and ActiveSupport's inflector for associations.
require "alba"

Alba.backend = :oj
Alba.inflector = :active_support
