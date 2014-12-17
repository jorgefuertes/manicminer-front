# Test jabber alarms

namespace :monitor do
    desc 'Test jabber alarms'
    task :test => :environment do
        logger.level = 4
        include JabberHelpers

        shell.say "••• TESTING JABBER ALARMS •••", [:white, :on_blue]
        message = shell.ask "> Alarm message? "

        shell.say "> Sending alarm... "
        sendJabberAlarm "ALARM TEST: #{message}"
        shell.say "OK", :green

        shell.say "DONE", :green
    end # End task
end # End namespace
