# plain Ruby:

class CurrentUser
  class << self
    attr_reader :id, :name, :timezone

    def init(id:, name:, timezone: nil)
      raise "Attemting to initialize CurrentUser when it was already done" unless init?

      @defined = true

      @id = id
      @name = name
      @timezone = timezone || Notif.find_by(user_id: @id)&.timezone || Notif::DEFAULT_TIMEZONE
    end

    def init?
      @defined.nil?
    end

    # do only at ertry point in app to ensure clear state
    def deinit
      @defined = nil
    end
  end
end

# rails singleton:

proc {
require "singleton"

class CurrentUser
  include Singleton

  attr_reader :ident, :name

  def initialize
    @initialized = false
  end

  # initializes CurrentUser's uniq id and name to display (values from Slack)
  def init(ident, name)
    raise "Attemting to initialize CurrentUser when it was already done" if @initialized

    @initialized = true

    @ident = ident
    @name =  name
  end

  def init?
    @initialized
  end
end

proc { # tests:
u = CurrentUser.instance
puts u.init?
u.init('123', 'Maxx')
puts u.init?
puts "'#{u.name}' (#{u.ident})"
u.init('124', 'Maks')
}

}
