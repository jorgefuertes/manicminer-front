# form_helper.rb

ManicminerPool::App.helpers do

	def tooltipLabel(label, tip)
		%{
			<label>
				<span data-tooltip="" class="has-tip tip-top" title="#{t tip}">
					#{t label}
					<span class="tt">?</span>
				</span>
			</label>
		}
	end

	def tooltipLabelNoT(label, tip)
		%{
			<label>
				<span data-tooltip="" class="has-tip tip-top" title="#{tip}">
					#{label}
					<span class="tt">?</span>
				</span>
			</label>
		}
	end

	def getLabelFor(form, name)
		if  /^translation missing/.match(t("forms.#{form}.#{name}.tip"))
			label = t "forms.#{form}.#{name}.label"
			return %{<label><strong>#{label}</strong></label>}
		else
			return tooltipLabel "forms.#{form}.#{name}.label", "forms.#{form}.#{name}.tip"
		end
	end

	def getPlaceholderFor(form, name)
		if  /^translation missing/.match(t("forms.#{form}.#{name}.placeholder"))
			return ""
		else
			return t "forms.#{form}.#{name}.placeholder"
		end
	end

	def inputField(form, type, name, attributes = {})
		attributesOut = ""
		attributes[:placeholder] = getPlaceholderFor(form, name) if attributes[:placeholder].nil?
		attributes.each do |key, value|
			attributesOut += %{#{key}="#{value}" }
		end
		%{<input id="#{name}-input" type="#{type}" name="#{name}" #{attributesOut}/>}
	end

	def smallError(text)
		%{<small class="error">#{t text}</small>}
	end

	def completeInputField(form, type, name, attributes = {})
		if attributes[:readonly].nil?
			%{
				<div class="#{name}-field">
					#{getLabelFor form, name}
					#{inputField form, type, name, attributes}
					#{smallError "forms.#{form}.#{name}.error"}
				</div>
			}
		else
			%{
				<div class="#{name}-field">
					#{getLabelFor form, name}
					#{inputField form, type, name, attributes}
				</div>
			}
		end
	end

	def completeRangeField(form, name, min, max, initial)
		%{
			<div class="#{name}-field">
				#{getLabelFor form, name}
				<input id="#{name}-input" type="number" name="#{name}"
					min="#{min}" max="#{max}" value="#{initial}" readonly />
				#{smallError "forms.#{form}.#{name}.error"}
			</div>
			<div id="#{name}-slider" class="range-slider" data-slider=""
				data-options="start: #{min}; end: #{max}; initial: #{initial};">
				<span class="range-slider-handle"></span>
				<span class="range-slider-active-segment"></span>
				<input type="hidden">
			</div>
		}
	end

	def oldPasswordField(form)
		attributes = {:required => true, :pattern => "^.{5,50}$", :autocomplete => :off}
		%{
			<div class="password-field">
				#{getLabelFor form, 'oldPassword'}
				#{inputField form, 'password', 'oldPassword', attributes}
				#{smallError("forms.#{form}.password.error")}
			</div>
		}
	end

	def completePasswordField(form)
		attributes = {:required => true, :pattern => "^.{5,50}$", :autocomplete => :off}
		attributesConfirm = attributes
		attributesConfirm[:"data-equalto"] = 'password-input'
		%{
			<div class="password-field">
				#{getLabelFor form, 'password'}
				#{inputField form, 'password', 'password', attributes}
				#{getLabelFor form, 'password_confirmation'}
				#{inputField form, 'password', 'password_confirmation', attributesConfirm}
				#{smallError("forms.#{form}.password.error")}
			</div>
		}
	end

	def completeRadioCombo(form, name, options = {})
		output = %{
			<div class="#{name}-field">
				#{getLabelFor form, name}
		}
		options.each do |value, checked|
			if checked
				output << %{
					<input id="#{name}-#{value}" type="radio" name="#{name}" value="#{value}" checked="checked" />}
			else
				output << %{<input id="#{name}-#{value}" type="radio" name="#{name}" value="#{value}" />}
			end
			label = t "forms.#{form}.#{name}.#{value}"
			output << %{<label for="#{name}-#{value}">#{label}</label>"}
		end
		output << %{</div>}

		return output
	end

	def completeTextArea(form, name, attributes = {})
		attributes[:placeholder] = getPlaceholderFor form, name
		attributesOut = ""
		attributes.each do |key, value|
			attributesOut << %{#{key}="#{value}" } if key != 'value'
		end
		content = ""
		content = attributes[:value] if attributes[:value]
		%{
			<div class="#{name}-field">
				#{getLabelFor form, name}
				<textarea name="#{name}" id="#{name}-textarea" #{attributesOut}>#{content}</textarea>
				#{smallError "forms.#{form}.#{name}.error"}
			</div>
		}
	end

	def completeCheckBoxField(form, name, boolValue = false, attributes = {})
		attributes[:checked] = 'checked' if boolValue == true
		return completeInputField form, 'checkbox', name, attributes
	end

	def nonEditField(form, name, value)
		if value.kind_of?(FalseClass) or value.kind_of?(TrueClass)
			colorClass = value.to_s
			value = t "bool.#{value.to_s}"
			value.upcase!
		end
		%{
			#{getLabelFor form, name}
			<div class="non-edit #{colorClass}">#{value}</div>
		}
	end
end
