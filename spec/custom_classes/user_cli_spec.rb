require "rails_helper"

RSpec.describe UserCli do # TODO: use fixtures, or better, factorybot
  it "reacts to unknown commands" do
    expect(UserCli.exec_command("unknown-command")).to match(/Unknown command/i)
  end

  it "knows its user" do
    CurrentUser.deinit
    CurrentUser.init(id: "12345", name: "Maxx")

    expect(UserCli.exec_command("user-info")).to include("Maxx")
    expect(UserCli.exec_command("user-info")).to include("12345")

    expect(UserCli.exec_command("user-info", user_id: "54321", user_name: "Maks")).to include("Maks")
    expect(UserCli.exec_command("user-info", user_id: "54321", user_name: "Maks")).to include("54321")
  end

  it "ignores colon" do
    expect(UserCli.exec_command("help:")).to include("Help:")
    expect(UserCli.exec_command("help")).to include("Help:")

    expect(UserCli.exec_command("timetable:")).to include("Timetable for")
    expect(UserCli.exec_command("timetable")).to include("Timetable for")
  end
end
