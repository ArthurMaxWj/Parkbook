# Web Conversion  Console, aka. WebConvCons
# Converts txt back into nice html (better alternative to 'display: :web' from UserCli).
class WebConvCons
  NON_ELEM = ['', '---', '======']

  # CSS config: -------------------------------

  UL_CLASS = 'wcc-list'

  NORMAL_EL_CLASS = 'wcc-elem wcc-elem-normal'
  SUB_EL_CLASS = 'wcc-elem wcc-elem-sub'
  HEADER_EL_CLASS = 'wcc-elem wcc-elem-header'

  DELIM_CLASS = 'wcc-elem-delim'

  PARAM_EMPH_CLASS = 'wcc-emph wcc-emph-param'
  COMMAND_EMPH_CLASS = 'wcc-emph wcc-emph-cmd'

  CONTROLS_CLASS = 'wcc-controls'
  LINK_CLASS = 'wcc-link'
  FIELD_CLASS = 'wcc-field'

  #  Stimulus config: --------------------------

  STIMULUS_CONTROLLER = 'wccont'

  STIMULUS_ACTION_COMMAND_METHOD = 'exec'
  STIMULUS_ACTION_COMMAND = "click->#{STIMULUS_CONTROLLER}\##{STIMULUS_ACTION_COMMAND_METHOD}"

  # NOTE: but remember that it might not always be the same controller!!!
  STIMULUS_ACTION_FIELD_METHOD = 'rehref'
  STIMULUS_ACTION_FIELD = "#{STIMULUS_CONTROLLER}\##{STIMULUS_ACTION_FIELD_METHOD}" # defaults to input->...

  # when enter clicked it's the same as if button clicked, (keypress starts action that starts button's action)
  STIMULUS_ACTION_ENTER_METHOD = 'enter'
  STIMULUS_ACTION_ENTER = "keypress->#{STIMULUS_CONTROLLER}\##{STIMULUS_ACTION_ENTER_METHOD}"

  STIMULUS_TARGET_FIELD = 'cmdline'
  STIMULUS_TARGET_LINK = 'run'

  STIMULUS_TARGET_COMMAND = 'cmd'

  def on_stimulus(val)
    @stimulus ? val : ''
  end

  # actual code starts here: --------------------

  def self.convert(textual_representation, stimulus: true)
    WebConvCons.new.convert(textual_representation, stimulus: stimulus)
  end

  def convert(textual, stimulus: true)
    # violating Functional Programming here, with that class var
    # But it's for a good cause, readability.
    @lines = textual.split("\n")
    @stimulus = stimulus

    html = []

    html << "<div #{on_stimulus('data-controller="' + STIMULUS_CONTROLLER + '"')}>"
    html << on_stimulus(
      "<div class=\"#{CONTROLS_CLASS}\">" +
        '<input type="text" value="help" ' + "data-#{STIMULUS_CONTROLLER}-target=\"#{STIMULUS_TARGET_FIELD}\" data-action=\"" +
        "#{STIMULUS_ACTION_FIELD} #{STIMULUS_ACTION_ENTER}\" class=\"#{FIELD_CLASS}\"/>" +
        '<a href="/web-console?cmd=help" ' + "data-#{STIMULUS_CONTROLLER}-target=\"#{STIMULUS_TARGET_LINK}\" class=\"#{LINK_CLASS}\">Run</a>" +
      '</div>'
    )
    html << "<ul class=\"#{UL_CLASS}\">"
    @lines.each_with_index do |l, i|
      html << to_elem_li(l, i)
    end
    html << '</ul></div>'

    html.join("\n")
  end

  # return element with the right class and optionally delim class
  # Header elem shouldn't have delim applied -- actually, adding delim shouldn't have any effect on it's CSS.
  def determine_elem_type(l, i)
    return elem_header(l) if @lines[i + 1] == '======'

    add_delim = @lines[i + 1] == '---'

    return elem_sub(l[2..], delim: add_delim) if l[0..1] == '|:' # from 2 becouse of space

    return elem_normal(l, delim: add_delim) unless NON_ELEM.include?(l)

    ''
  end

  def to_elem_li(l, i)
    elem = determine_elem_type(l, i)

    action_attr = "data-action=\"#{STIMULUS_ACTION_COMMAND}\""
    command_target =  'data-' + STIMULUS_CONTROLLER + '-' + STIMULUS_TARGET_COMMAND + '-target'
    command_dataset = 'data-' + STIMULUS_TARGET_COMMAND

    # this is needed to resolve the order of substitutions, or else there will be substitutions like:
    #   "`cmd:` and `cmd`" into "<emph>cmd:` and `cmd</emph>"
    elem.gsub(/(`)([^`]*)(:`)(.*)(`)([^`]*[^:])(`)/,
              "<emph class=\"#{PARAM_EMPH_CLASS}\">\\2</emph>\\4<emph class=\"#{COMMAND_EMPH_CLASS}\" #{on_stimulus(
                action_attr + ' ' + (command_dataset + '="\6"')
              )}>\\6</emph>")

    elem.gsub(/(`)([^`]*)(:`)/, "<emph class=\"#{COMMAND_EMPH_CLASS}\" #{on_stimulus(
              action_attr + ' ' + (command_dataset + '="\2"')
            )}>\\2</emph>")
        .gsub(/(`)([^`]*[^:])(`)/, "<emph class=\"#{PARAM_EMPH_CLASS}\">\\2</emph>")
  end

  def elem(klass, content, delim:)
    delim_txt = delim ? ' ' + DELIM_CLASS : ''
    "<li class=\"#{klass + delim_txt}\">#{content}</li>"
  end

  def elem_sub(content, delim:)
    elem(SUB_EL_CLASS, content, delim: delim)
  end

  def elem_normal(content, delim:)
    elem(NORMAL_EL_CLASS + ' ' + (content.include?(UserCli::SIGN_OF_ERROR) ? UserCli::CLI_ERROR_CLASS : ''), content,
         delim: delim)
  end

  def elem_header(content)
    elem(HEADER_EL_CLASS, content, delim: false) # header has it's own delim build-in in css (should have)
  end
end
