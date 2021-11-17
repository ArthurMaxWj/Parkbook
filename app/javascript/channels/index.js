// Load all the channels within this directory and all subdirectories.
// Channel files must be named *_channel.js.


import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"
import * as Turbo from "@hotwired/turbo"

const channels = require.context('.', true, /_channel\.js$/)
channels.keys().forEach(channels)


const application = Application.start()
const context = require.context("../stimulus_controllers", true, /\.js$/)
application.load(definitionsFromContext(context))
