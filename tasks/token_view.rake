# View a token

namespace :token do
    desc 'View token information'
    task :view => :environment do
        logger.level = 4
        shell.say "> View token's information"
        tokenStr = shell.ask "Token string? "
        shell.say "> Seeking token: #{tokenStr}"
        token = Token.where(:token => tokenStr).first
        if token
        	shell.say "ID......: #{token.id}"
        	shell.say "USER....: #{token.user.name} - #{token.user.email} CONF: #{token.user.emailConfirm}"
        	shell.say "KIND....: #{token.kind}"
        	shell.say "TOKEN...: #{token.token}"
        	shell.say "EXPIRES.: #{token.expires}"
        	shell.say "USED....: #{token.used}"
        	shell.say "OPENED..: #{token.opened}"
        	shell.say "CREATED.: #{token.created_at}"
        	shell.say "UPDATED.: #{token.updated_at}"
        else
        	shell.say "Token not found!"
        end
        shell.say "Done"
    end # End task
end # End stats
