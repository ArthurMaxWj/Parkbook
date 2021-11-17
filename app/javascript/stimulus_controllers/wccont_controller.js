import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'cmd', 'cmdline', 'run' ]
  

  // prepares selected command for execution
  exec(e) {
    // changes and focuses textfield
    this.cmdlineTarget.value = e.currentTarget.dataset.cmd + ' ' // space prepared for adding params
    this.cmdlineTarget.focus()

    this.runTarget.href  = '/web-console?cmd=' + e.currentTarget.dataset.cmd
  }

  // changes target command
  rehref() {
    console.log('ok')
    this.runTarget.href  = '/web-console?cmd=' + this.cmdlineTarget.value
  }

  // simulates clicking putton on enter
  enter(e) {
    if (e.key === 'Enter' || e.keyCode === 13) {
        this.runTarget.click();
    }
  }
}
