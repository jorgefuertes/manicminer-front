# ui_helper.rb

module UiHelpers

    def alert(contentText = 'Alert!', kind = :info, icon = 'fi-info')
        %{
            <div data-alert="" class="alert-box round #{kind}">
                <i class="#{icon}"></i>
                <span class="text">#{contentText}</span>
                <a href="#" class="close">&times;</a>
            </div>
        }
    end

    def flashSection
		kinds = {
            :success => 'fi-check',
            :error   => 'fi-prohibited',
            :info    => 'fi-info',
            :warning => 'fi-alert',
            :notice  => 'fi-info'
        }

        output = ""
        kinds.each do |kind, icon|
        	text = flash[kind]
        	next if text.blank?
        	output += alert text, kind, icon
            flash[kind] = nil
        end

        return output
    end

    def boolToHuman(value = false)
        return t("bool.#{value.to_s}")
    end

    def boolToHumanLabel(value = false)
        if value
            kind = :success
        else
            kind = :alert
        end

        return "<span class=\"#{kind} label radius\">#{boolToHuman value}</span>"
    end

    # Returns an example user.worker string:
    def userWorkerExample
        return 'user.worker' unless current_account and current_account.workers.count > 0
        return "#{current_account.name}.#{current_account.workers.first.name}"
    end

	def ajaxLoader
		"<img alt=\"...\" src=\"/images/loader.gif\" width=\"20\" height=\"20\" />"
	end

    def noFloatZero(number)
        return "%g" % number if number.is_a? Float
        return number
    end

    def floatToHuman(number)
        unless number.is_a? String
            return 0 if number == 0
            return ('%.8f' % number).sub(/\.*0+$/, '')
        end
        return number
    end

    def missingWallets
        missing = false
        Coin.where(:active => true).each_with_index do |coin, index|
            missing = true unless current_account.wallets.first(:coin_id => coin.id)
            break if missing == true
        end

        return missing
    end

    def walletMissingList
        output = ""
        Coin.where(:active => true).each_with_index do |coin, index|
            unless current_account.wallets.first(:coin_id => coin.id)
                output += ', ' unless output.size == 0
                output += "<strong>#{coin.name}</strong>"
            end
        end

        return output
    end

    def walletMissingColorList
        output = ""
        size = Coin.where(:active => true).count
        Coin.where(:active => true).each_with_index do |coin, index|
            cl = current_account.wallets.first(:coin_id => coin.id) ? 'true' : 'false'
            output += "<span data-tooltip=\"\" class=\"#{cl} has-tip tip-top\" title=\"#{coin.name}\">"\
                        "#{coin.symbol}</span>"
            output += '<span class="separator">&middot;</span>' unless index == size - 1
        end

        return output
    end

    def cutTo(text, numChars)
        return text if text.size <= numChars
        return "#{text[0..numChars]}…"
    end

    def gravatarImgTag(user)
        hash = Digest::MD5.hexdigest(user.email.downcase)
        url = "http://www.gravatar.com/avatar/#{hash}.jpg?s=80"
        return "<img src=\"#{url}\" alt=\"#{user.name}\" width=\"80\" height=\"80\" />"
    end

    def getSymbolColor(symbol)
        key = "#{symbol}-color-class"
        return getRedisKey(key) if getRedisKey(key)
        coin = Coin.first(:symbol => symbol)
        colorClass = 'zx-black'
        colorClass = coin.colorClass if coin
        setRedisKey(key,colorClass, 3600)
        return colorClass
    end
    
    # Return the file size with a readable style.
    def bytesToHuman(size, precision = 2)
        gigasz = 1073741824.0
        megasz = 1048576.0
        kilosz = 1024.0
        return "1 Byte" if size == 1
        return "%d Bytes" % size if size < kilosz
        return "%.#{precision}f KB" % (size / kilosz) if size < megasz 
        return "%.#{precision}f MB" % (size / megasz) if size < gigasz
        return "%.#{precision}f GB" % (size / gigasz)
    end    
end

ManicminerPool::App.helpers UiHelpers
