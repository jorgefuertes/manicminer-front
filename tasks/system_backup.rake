# All backup

namespace :system do
    desc 'Make complete system backup'
    task :backup => :environment do
        logger.level = 4
        require 'fileutils'
        include CoindHelpers
        include UiHelpers
        include JabberHelpers
        require 'date'

        backupPath = "#{Padrino.root}/backup"
        FileUtils.mkdir_p backupPath
        FileUtils.mkdir_p "#{backupPath}/database"
        FileUtils.mkdir_p "#{backupPath}/wallets"

        while true do
            alarm_log = ""
            # Coins backup
            shell.say "••• Coins backup •••", [:white, :on_blue]
            total_bk_size = 0
            Coin.where(:active => true).each do |coin|
                error = false
                timeString = Time.now.utc.strftime "%d%m%Y_%H%M%S%Z"
                log = "Starting #{coin.name} backup at #{timeString}."
                fileName   = "#{coin.symbol.downcase}-wallet_#{timeString}.dat"
                remoteName = "/tmp/#{fileName}"
                localName  = "#{backupPath}/wallets/#{coin.symbol}/#{fileName}"
                FileUtils.mkdir_p "#{backupPath}/wallets/#{coin.symbol}"
                client = getCoinClient(coin)
                bk = Backup.create(
                    :name => "#{coin.symbol} backup",
                    :path => localName,
                    :kind => 'wallet',
                    :completed => false
                )
                raise "Error creating Backup object!" unless bk
                begin
                    shell.say " #{coin.symbol}:", :cyan
                    shell.say "  Remote: ", :yellow
                    shell.say "#{remoteName} "
                    client.backupwallet(remoteName)
                    shell.say "OK", :green
                    log += "\nRemote #{remoteName}: OK."
                rescue Exception => e
                    error = true
                    shell.say "FAIL", :red
                    shell.say "  * ", :red
                    shell.say "#{e.message}"
                    log += "\nRemote #{remoteName}: FAIL."
                    log += "\nException: #{e.inspect}"
                    alarm_log += "\nException: #{e.inspect}"
                end

                unless error
                    begin
                        shell.say "  Local: ", :yellow
                        shell.say "#{localName} "
                        Net::SCP.start(coin.rpcHost, 'root', :keys => '/root/.ssh/id_rsa') do|scp|
                            scp.download!(remoteName, localName)
                        end
                        shell.say "OK", :green
                        log += "\nSCP to #{localName}: OK."
                    rescue Exception => e
                        error = true
                        shell.say "FAIL", :red
                        shell.say "  * ", :red
                        shell.say "#{e.message}"
                        log += "\nSCP to #{localName}: FAIL."
                        log += "\nException: #{e.inspect}"
                        alarm_log += "\nException: #{e.inspect}"
                   end
                end

                unless error
                    begin
                        shell.say "  Remove remote file: ", :yellow
                        Net::SSH.start(coin.rpcHost, 'root', :keys => '/root/.ssh/id_rsa') do|ssh|
                            ssh.exec!("rm #{remoteName}")
                        end
                        shell.say "OK", :green
                        log += "\nRM remote: OK."
                    rescue Exception => e
                        error = true
                        shell.say "FAIL", :red
                        shell.say "  * ", :red
                        shell.say "#{e.message}"
                        log += "\nRM remote: FAIL."
                        log += "\nException: #{e.inspect}"
                        alarm_log += "\nException: #{e.inspect}"
                    end
                end

                unless error
                    size = File.size localName
                    bk.size = size
                    shell.say "  Compressing #{bytesToHuman size}: ", :yellow
                    bzipResult = system "bzip2 -9 #{localName}"
                    if bzipResult
                        sizeBz = File.size "#{localName}.bz2"
                        shell.say "#{bytesToHuman sizeBz} "
                        shell.say "OK", :green
                        log += "\nBZIP2: Compress #{bytesToHuman size} to #{bytesToHuman sizeBz} at #{localName}.bz2 OK"
                        bk.path = "#{localName}.bz2"
                        bk.size = sizeBz
                    else
                        error = true
                        shell.say "FAIL", :red
                        log += "\nBZIP2 #{localName}.bz2: FAIL."
                        alarm_log += "\nBZIP2 #{localName}.bz2: FAIL."
                    end
                end

                bk.completed = true unless error
                bk.log = log
                bk.save
                total_bk_size += bk.size
            end

            shell.say
            shell.say "TOTAL Coins backup size: ", [:white, :on_blue]
            shell.say bytesToHuman total_bk_size
            shell.say

            # Delete old coin backups
            shell.say "••• Delete old coins backups •••", [:white, :on_blue]
            limit_date = Date.today - 1
            shell.say "Limit is #{limit_date}"
            Coin.find_each do |coin|
                coin_backups = Backup.where(:kind => 'wallet').where(:name => "#{coin.symbol} backup").order(:created_at)
                shell.say " #{coin.symbol}: ", :cyan
                shell.say "#{coin_backups.count} backups"
                counter = coin_backups.count
                coin_backups.each do |bk|
                    shell.say "    #{bk.name} #{bk.created_at} "
                    if counter == 1
                        shell.say "last one ", :blue
                        shell.say "PRESERVE", :green
                    elsif bk.created_at < limit_date
                        shell.say "DELETE ", :blue
                        shell.say "#{bk.path} "
                        if File.exist?(bk.path)
                            FileUtils.rm bk.path, :force => true
                            shell.say "OK", :green
                        else
                            shell.say "DOESN'T EXISTS", :red
                        end
                        counter -= 1
                        bk.destroy
                    else
                        shell.say "FRESH", :green
                    end
                end
            end

            # Database backup
            shell.say
            shell.say "••• Database Backup •••", [:white, :on_blue]
            db_name    = MongoMapper.database.name
            db_host    = MongoMapper.database.connection.host
            db_port    = MongoMapper.database.connection.port
            timeString = Time.now.utc.strftime "%d%m%Y_%H%M%S%Z"
            dump_path  = "#{backupPath}/database/#{db_name}_#{timeString}"
            error      = false
            log = "Starting database #{db_name} backup at #{timeString}."

            shell.say "  Dumping database ", :cyan
            shell.say "#{db_name} "
            bk = Backup.create(
                :name => "#{db_name} backup",
                :path => "#{dump_path}.tar.bz2",
                :kind => 'database',
                :completed => false
            )
            command = "mongodump -d #{db_name} -h #{db_host} --port #{db_port} -o #{dump_path} > /dev/null"
            log += "\n#{command} "
            result = system command
            if result
                log += "OK"
                shell.say "OK", :green
                shell.say "  Compressing... "
                command = "tar -C #{backupPath}/database -cjf #{dump_path}.tar.bz2 #{db_name}_#{timeString}"
                log += "\n#{command} "
                result = system command
                if result
                    log += "OK"
                    shell.say "OK ", :green
                    bk.size = File.size "#{dump_path}.tar.bz2"
                    shell.say bytesToHuman bk.size
                    unless dump_path.to_s == ""
                        shell.say "  Deleting dump dir... "
                        command = "rm -Rf #{dump_path}"
                        log += "\n#{command} "
                        result = system command
                        if result
                            log += "OK"
                            shell.say "OK", :green
                            bk.completed = true
                        else
                            log += "FAIL"
                            shell.say "FAIL", :red
                            alarm_log += "\nDatabase dump FAIL on deleting dump dir"
                        end
                    end
                else
                    log += "FAIL"
                    shell.say "FAIL", :red
                    alarm_log += "\nDatabase dump FAIL making tarball"
                end
            else
                log += "FAIL"
                shell.say "FAIL", :red
                alarm_log += "\nDatabase dump FAIL"
            end

            bk.log = log
            bk.save

            unless alarm_log == ""
                shell.say "> Sending alarm... "
                sendJabberAlarm "SYSTEM BACKUP ERRORS: #{alarm_log}"
                shell.say "OK", :green
            end

            # Delete old database backups
            shell.say "••• Delete old database backups •••", [:white, :on_blue]
            limit_date = Date.today - 1
            shell.say "Limit is #{limit_date}"
            db_backups = Backup.where(:kind => 'database').order(:created_at)
            shell.say "#{db_backups.count} backups"
            counter = db_backups.count
            db_backups.each do |bk|
                shell.say "    #{bk.name} #{bk.created_at} "
                if counter == 1
                    shell.say "last one ", :blue
                    shell.say "PRESERVE", :green
                elsif bk.created_at < limit_date
                    shell.say "DELETE ", :blue
                    shell.say "#{bk.path} "
                    if File.exist?(bk.path)
                        FileUtils.rm bk.path, :force => true
                        shell.say "OK", :green
                    else
                        shell.say "DOESN'T EXISTS", :red
                    end
                    counter -= 1
                    bk.destroy
                else
                    shell.say "FRESH", :green
                end
            end

            # Check for outsiders
            shell.say "••• Checking for outsiders •••", [:white, :on_blue]
            Dir["#{backupPath}/database/*", "#{backupPath}/wallets/*/*"].each do |f|
                bk = Backup.where(:path => f).first
                unless bk
                    shell.say "  #{f} "
                    shell.say "NO REGISTERED ", :red
                    FileUtils.rm f, :force => true
                    shell.say "DELETED", :blue
                end
            end

            shell.say
            shell.say " * DONE * ", [:black, :on_green]
            shell.say "> Sleeping 1 hour..."
            shell.say
            sleep 60 * 60
        end # Main loop

    end # End task
end # End namespace
