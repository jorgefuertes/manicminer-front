# jabber_helper.rb

module JabberHelpers
    include Jabber

    def sendJabberAlarm(message)
        # Change this to a valid jabber user
    	username = 'manicminer.alarms@gmail.com'
    	password = '...'
    	Client.new(JID.new "#{username}/Home").instance_eval do
    		connect 'talk.google.com'
    		auth    password
    		send    Message.new('first-admin@gmail.com', message).tap{|m| m.type = :chat }
    		send    Message.new('second-admin@gmail.com', message).tap{|m| m.type = :chat }
    		close
    	end
    end

end #module

ManicminerPool::App.helpers JabberHelpers
