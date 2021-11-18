class UserCli
  DEFAULT_CMD = 'help'
  STAR_COMMANDS = ['help', 'user-info', 'timetable'] # commands that are independent of position or can work on all/any (position=* instead of a number)
  SIGN_OF_ERROR = 'Error:' # used with 'include?' to check when result contains error
  CLI_ERROR_CLASS = 'wcc-elem-err'

  def self.exec_command(cmd_str, display: :txt, escape_html: false, user_id: nil, user_name: nil, timezone: nil)
    raise 'either provide both, "user_id" and "user_name" to "exec_command" or none' if (user_id.nil? && !user_name.nil?) || (!user_id.nil? && user_name.nil?)

    UserCli.new.exec_command(cmd_str, escape_html: escape_html, display: display, user_id: user_id || CurrentUser.id,
                                      user_name: user_name || CurrentUser.name, timezone: timezone)
  end

  def exec_command(cmd_str, escape_html: false, display: :txt, user_id: user_id = CurrentUser.id, user_name: user_name = CurrentUser.name, timezone: nil)
    raise 'either provide both, "user_id" and "user_name" to "exec_command or none' if (user_id.nil? && !user_name.nil?) || (!user_id.nil? && user_name.nil?)

    @user_id = user_id || CurrentUser.id
    @user_name = user_name || CurrentUser.name

    @timezone ||= CurrentUser.timezone

    @join = false
    @escape_html = escape_html

    @display = display
    cmd_str.strip!
    cmd_words = cmd_str.split

    # checking if there is parking position before actual command name
    if (/\d+|\*/.match?(cmd_words[0]))
      @position = cmd_words[0]
      return arg_err("Star position is not allowed for this command") if @position == '*' && !STAR_COMMANDS.include?(cmd_words[1] || DEFAULT_CMD)

      cmd_words = cmd_words[1..]
    else
      @position = 1
    end

    cmd_words << DEFAULT_CMD if cmd_words.empty?
    cmd_name = cmd_words[0]
    cmd_name = cmd_name[..-2] if cmd_name[-1] == ':' # colons ok, commands 'help:' and 'help' are the same

    words = cmd_words[1..]
    begin
      result = select_and_parse(cmd_name, words)
      @escape_html = false if result.include?(SIGN_OF_ERROR)
      result = @escape_html ? (@join ? result.map { |r| CGI::escapeHTML(r) } : CGI::escapeHTML(result)) : result
      @join ? result.join(delim) : result
    rescue ArgumentError => e
      if e.message.include?('argument out of range')
        range_arg_err
      else
        raise # not that one, re-raise
      end
    end
  end

  def select_and_parse(cmd_name, words) # OPTIMIZE you can create service for loading params
    case cmd_name
    when 'help'
      help
    when 'book'
      case words.length
      when 0
        book(nil, nil, nil)
      when 1
        start = TimeUtils.read_time(words[0])
        return book(nil, start, nil) unless start.nil?

        day = TimeUtils.read_date(words[0])
        return arg_err('If booking for day different from today, state starting date') unless day.nil?

        syntax_arg_err
      when 2
        day = TimeUtils.read_date(words[0])
        start = TimeUtils.read_time(words[1])
        return book(day, start, nil) unless day.nil? || start.nil?

        start = TimeUtils.read_time(words[0])
        finish = TimeUtils.read_time(words[1])
        return book(nil, start, finish) unless start.nil? || finish.nil?

        puts "start: #{words[0]}, finish: #{finish}"

        arg_err
      when 3
        day = TimeUtils.read_date(words[0])
        start = TimeUtils.read_time(words[1])
        finish = TimeUtils.read_time(words[2])
        return book(day, start, finish) unless day.nil? || start.nil? || finish.nil?

        syntax_arg_err
      end
    when 'release'
      case words.length
      when 0
        release(nil, nil, nil)
      when 1
        finish = TimeUtils.read_time(words[0])
        return release(nil, nil, finish) unless finish.nil?

        day = TimeUtils.read_date(words[0])
        return release(nil, nil, nil) unless day.nil?

        syntax_arg_err
      when 2
        day = TimeUtils.read_date(words[0])
        start = TimeUtils.read_time(words[1])
        return release(day, finish, nil) unless day.nil? || start.nil?

        start = TimeUtils.read_time(words[0])
        finish = TimeUtils.read_time(words[1])
        return release(nil, start, finish) unless start.nil? || finish.nil?

        arg_err
      when 3
        day = TimeUtils.read_date(words[0])
        start = TimeUtils.read_time(words[1])
        finish = TimeUtils.read_time(words[2])
        return relaease(day, start, finish) unless day.nil? || start.nil? || finish.nil?

        syntax_arg_err
      else
        argnum_arg_err
      end
    when 'cancel'
      if words.length == 1
        start = TimeUtils.read_time(words[0])
        return cancel(nil, start) unless start.nil?

        syntax_arg_err
      elsif words.length == 2
        day = TimeUtils.read_date(words[0])
        start = TimeUtils.read_time(words[1])
        cancel(day, start) unless day.nil? || start.nil?

        syntax_arg_err
      else
        argnum_arg_err
      end
    when 'notifs-on'
      return argnum_arg_err('Wrong argument number, use command `help:` (remember not to use spaces in phone number)') if words.length != 2
      return arg_err('Wrong medium, choose from: email, sms') if words[0] != 'email' && words[0] != 'sms'

      email = words[1]
      return syntax_arg_err('Wrong argument syntax (should match email), use command `help:`') unless URI::MailTo::EMAIL_REGEXP.match?(email)
      return notifs_on(email: email) if words[0] == 'email'

      sms = words[1]
      return syntax_arg_err('Wrong argument syntax (should match phone number, no spaces allowed), use command `help:`') unless (
        /^\+?\d{3,}$/.match?(email)
      )
      return notifs_on(sms: sms) if words[0] == 'sms'

      unknown_arg_err
    when 'notifs-off'
      return argnum_arg_err if words.length > 1
      return arg_err('Wrong medium, choose from: email, sms') if (
        words.length == 1 && words[0] != 'email' && words[0] != 'sms'
      )

      return notifs_off(medium: :both) if words.length == 0

      return notifs_off(medium: :email) if words[0] == 'email'

      return notifs_off(medium: :sms) if words[0] == 'sms'

      unknown_arg_err
    when 'timezone'
      return argnum_arg_err if words.length > 1

      return set_timezone(words[0]) if words.length == 1
      return get_timezone if words.length == 0

      unknown_arg_err
    when 'timetable'
      if words.length == 0
        timetable(nil)
      elsif words.length == 1
        day = TimeUtils.read_date(words[0])
        return syntax_arg_err if day.nil?

        timetable(day)
      else
        argnum_arg_err
      end
    when 'user-info'
      argnum_arg_err if words.length != 0

      user_info
    else
      unknown_command_err
    end
  end

  private

  # all errors:

  # OPTIMIZE consider using OOP or more FP

  # prototype for other errors (kind of abstract class)
  def cli_error(msg, err_type: 'Error')
    return "<div class=\"#{CLI_ERROR_CLASS}\" style=\"color: red\"><b>#{err_type}:</b> <span>#{msg}</span></div>"
      .html_safe if @display == :web

    "#{err_type}: #{msg}"
  end

  def arg_err(msg = 'Wrong arguments, use command `help:`')
    cli_error(msg, err_type: 'Argument Error')
  end

  def argnum_arg_err(msg = 'Wrong argument number, use command `help:`')
    arg_err('[Argument Number Argument Error] ' + msg)
  end

  def syntax_arg_err(msg = 'Wrong argument syntax, use command `help:`')
    arg_err('[Syntax Argument Error] ' + msg)
  end

  def range_arg_err(msg = 'Argument out of range (check your numbers, or use command `help:`)')
    arg_err('[Range Argument Error] ' + msg)
  end

  def zone_arg_err(msg = 'Invalid timezone, use command `help:`')
    arg_err('[Timezone Argument Error] ' + msg)
  end

  def unknown_arg_err(msg = 'Unknown argument error, notify administrators and use command `help:`')
    arg_err('[Unknown Argument Error] ' + msg)
  end

  def found_err(msg = 'Booking by this date time not found. Use command `timetable:` or check user with `user-info:`')
    cli_error(msg, err_type: 'Not Found Error')
  end

  def aval_err(msg = 'Booking by this datetime is not available. Use command `timetable:`')
    cli_error(msg, err_type: 'Availability Error')
  end

  # special error for unknown commands
  def unknown_command_err
    cli_error('Unknown command, use command `help:`', err_type: 'Unknown Command Error')
  end

  # all comands:

  # displays info about CLI and available commands
  def help
    info = []

    info << 'Help:'
    info << '======'
    info << '<parking-position>|* <command> <params>'
    info << "|: `parking-position` defaults to 1, or use '*'"
    info << "|: '*' can denote each place, but can only be used with certain commands: " + STAR_COMMANDS.join(', ')
    info << "|: commands can be followed in colon, it doesn't change their bebehavior haviour in any way, so 'help:' and 'help' are the same"
    info << '---'
    info << ''
    info << '`book:` <`day`: e.g. 30-12-2021)> <`start_time`: e.g. 10:30> <`finish_time`: e.g. 11:30> -- books parking space'
    info << '|: `day` defaults to today; `start_time` to now if day=today; `finish` required if `day`!=today'
    info << ''
    info << '`release:` <`day`: e.g. 30-12-2021)> <`start_time`: e.g. 10:30> <`finish_time`: e.g. 11:30> -- sets finish time to parking space'
    info << '|: `day` defaults to today; `start_time` to first unreleased; `finish` required if `day`!=today, else defaults to now'
    info << ''
    info << '`cancel:` <`day`: e.g. 30-12-2021)> <`start_time`: e.g. 10:30> -- deletes parking space'
    info << '|: `day` defaults to today; `start_time` is required'
    info << ''
    info << '`timetable:` <`day`: e.g. 30-12-2021)> -- show all reservations from given day'
    info << '|: `day` defaults to today'
    info << ''
    info << '`timezone:` <`zone`: e.g. Europe/Warsaw)> -- changes default timezone for current user'
    info << "|: if `zone` given sets user's timezone, else returns current timezone"
    info << '|: but if command has never been  used, timezone is ' + Notif::DEFAULT_TIMEZONE
    info << ''
    info << '`notifs-on:` email|sms <`email` or `sms`: e.g. "example@email.com" or "123456789">'
    info << '|: -- makes notifications send through selected medium after each "book" command'
    info << '|:'
    info << "|: `email` is email address matching 'URI::MailTo::EMAIL_REGEXP':"
    info << "|: 'URI::MailTo::EMAIL_REGEXP': #{URI::MailTo::EMAIL_REGEXP}"
    info << '|: `sms` is phone number, no spaces allowed, plus sign optional'
    info << ''
    info << '`notifs-off:` email|sms|<empty> -- stops notifications from being sent through selected medium after each "book" command'
    info << '|: empty medium turns off both'

    @join = true
    info
  end

  # books place on parking
  #
  # 'day' defaults to today
  # 'start' and 'finish' required only for days after today
  def book(day, start, finish)
    now = Time.now

    day ||= now.to_date
    start ||= now

    start = TimeUtils.fill_date_of_time(day, start, nosec: true)
    finish = TimeUtils.fill_date_of_time(day, finish, nosec: true) unless finish.nil?
    return aval_err('Selected time is not available. Use command `timetable:`') unless Booking.free_at?(start,
                                                                                                        (finish || start.end_of_day), position: @position.to_i,)

    b = Booking.quick(day, start, finish, user: @user_id, displayed_name: @user_name, position: @position.to_i)
    b.save

    # setting timezone
    zf_day, zf_start, zf_finish = b.zoned

    # formatting
    zf_day = TimeUtils.format_date(zf_day)
    zf_start = TimeUtils.format_time(zf_start)
    zf_finish = TimeUtils.format_time(zf_finish)

    b.send_notifs # all logic whether send or not and where handled by delegating (manually, not with build-in functions) to Notif model

    "Booked #{zf_day} from #{zf_start} to #{zf_finish}"
  end

  # releases place on parking
  #
  # 'day' defaults to today
  # 'finish' required only for days after today
  # 'start' can be added if there are many bookings per day
  #   (even then defaults to first booking without release time)
  def release(day, start, finish)
    now = Time.now

    day ||= now.to_date
    finish ||= now

    b = nil
    if start.nil?
      b = Booking.order(booked: :asc).find_by(position: @position.to_i, day: day, released: nil, user: @user_id) # first not released
      return found_err('No unreleased booking that day.') if b.nil?
    else
      b = Booking.find_by(position: @position.to_i, day: day, booked: start, user: @user_id)
      return found_err if b.nil?
      return arg_err('This booking is already released. You can cancel and book again instead.') if b.released?
    end

    finish = TimeUtils.fill_date_of_time(day, finish, nosec: true)

    b.release(finish) # . b.update(released: finish)

    # setting timezone
    zf_day, zf_start, zf_finish = b.zoned

    # formatting
    zf_day = TimeUtils.format_date(zf_day)
    zf_start = TimeUtils.format_time(zf_start)
    zf_finish = TimeUtils.format_time(zf_finish)

    "Released #{zf_start} (#{zf_day}) to #{zf_finish}"
  end

  # deletes booking
  #
  # 'day' defaults to today
  # 'start' is required
  def cancel(day, start)
    now = Time.now

    day ||= now.to_date
    start = TimeUtils.fill_date_of_time(day, start, nosec: true)

    b = Booking.find_by(position: @position.to_i, user: @user_id, day: day, booked: start)
    return found_err('Booking by this datetime not found for your user. Use `timetable:` command') if b.nil?

    b.delete

    # setting timezone
    zf_day, zf_start, zf_finish = b.zoned

    # formatting
    zf_day = TimeUtils.format_date(zf_day)
    zf_start = TimeUtils.format_time(zf_start)
    zf_finish = TimeUtils.format_time(zf_finish)

    "Canceled booking  #{zf_day} #{zf_start}-#{zf_finish}"
  end

  def get_timezone
    @timezone
  end

  # changes default timezone for current user
  def set_timezone(zone)
    begin
      Time.now.in_time_zone(zone)
    rescue ArgumentError => e
      if e.message.include?('Invalid Timezone')
        return zone_arg_err
      else
        raise # not that one, re-raise
      end
    end

    Notif.find_or_create_by(user_id: @user_id).update(timezone: zone)
    "Timezone successfully changed to #{zone}"
  end

  # displays history for a given day
  #
  # 'day' defaults to today
  def timetable(day)
    day ||= Time.now.to_date

    info = []
    info << "Timetable for #{TimeUtils.format_date(day.in_time_zone(@timezone))} #{(@position == '*') ? '(all places)' : ('(place ' + @position.to_s + ')')}:"

    all_in_day = if @position != '*'
      Booking.order(booked: :desc).where(position: @position.to_i, day: day)
    else
      Booking.order(booked: :desc).where(day: day)
    end

    all_in_day.find_each do |b|
      info << display_booking_seq(b)
    end

    @join = true
    info
  end

  # just for 'timetable' function above
  def display_booking_seq(b)
    "|: #{ @position == '*' ? '[' + b.position.to_s + '] ' : ''
        }from #{TimeUtils.format_time(b.zoneified[:booked])} to #{TimeUtils.format_time(b.zoneified[:released])} by '#{b.displayed_name}'"
  end

  def user_info
    info = []
    info << "User's info: "
    info << "|: You are '#{@user_name}', your id is '#{@user_id}'"

    @join = true
    info
  end

  # makes email and sms confirmations send after using command 'book ''
  #
  # 'medium' is 'email' or 'sms', required
  def notifs_on(email: nil, sms: nil)
    unless email.nil?
      n = Notif.find_by(position: @position.to_i, user_id: @user_id)
      if n.nil?
        Notif.new(user_id: @user_id, email: email).save
      else
        n.update(email: email)
      end

      return "Email notification are turned ON for user '#{@user_name}' (#{email})"
    end

    unless sms.nil?
      n = Notif.find_by(position: @position.to_i, user_id: @user_id)
      if n.nil?
        Notif.new(user_id: @user_id, sms: sms).save
      else
        n.update(sms: sms)
      end

      return "SMS notification are turned ON, but currently not supported by server." if ENV['ENABLE_SMS'] == 'no'

      return "SMS notification are turned ON for user '#{@user_name}' (#{sms})"
    end
  end

  # makes email and sms confirmations stop being send after using command 'book'
  #
  # 'medium' is 'email' or 'sms' or not given
  # when empty switches off both
  def notifs_off(medium: :email)
    if medium == :both
      n = Notif.find_by(position: @position.to_i, user_id: @user_id)
      Notif.new(user_id: @user_id, email: nil, sms: nil).save unless n.nil?

      "Email and SMS notification are turned OFF for user #{@user_name}"
    elsif medium == :email
      n = Notif.find_by(position: @position.to_i, user_id: @user_id)
      Notif.new(user_id: @user_id, email: nil).save unless n.nil?

      "Email notification are turned OFF for user #{@user_name}"
    elsif medium == :sms
      n = Notif.find_by(position: @position.to_i, user_id: @user_id)
      Notif.new(user_id: @user_id, sms: nil).save unless n.nil?

      "SMS notification  are turned OFF for user #{@user_name}"
    end
  end

  # used to make end of line
  def delim
    (@display == :web) ? '<br />'.html_safe : "\n"
  end
end
