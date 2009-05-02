#!/usr/bin/env ruby

# this file auto-generates loaders for hyphenation patterns - to be improved

load 'languages.rb'

$package_name="hyph-utf8"


# TODO - make this a bit less hard-coded
$path_tex_generic="../../../tex/generic"
$path_loadhyph="#{$path_tex_generic}/#{$package_name}/loadhyph"

# TODO: should be singleton
languages = Languages.new.list

#text_if_native_utf = "\input pattern-loader.tex\n\\ifNativeUtfEightPatterns"

text_if_native_utf = <<EOT
% Test whether we received one or two arguments
\\def\\testengine#1#2!{\\def\\secondarg{#2}}
% That's Tau (as in Taco or ΤΕΧ, Tau-Epsilon-Chi), a 2-byte UTF-8 character
\\testengine Τ!\\relax
% Unicode-aware engine (such as XeTeX or LuaTeX) only sees a single (2-byte) argument
\\ifx\\secondarg\\empty
EOT

languages.each do |language|
	if language.use_new_loader then
		filename = "#{$path_loadhyph}/loadhyph-#{language.code}.tex"
		puts "generating '#{filename}'"
		File.open(filename, "w") do |file|
			# a message about auto-generation
			# TODO: write a more comprehensive one
			file.puts "% loadhyph-#{language.code}.tex"
			file.puts "%"
			file.puts "% Autogenerated loader for hyphenation patterns for \"#{language.name}\""
			file.puts "% by source/generic/hyph-utf8/generate-pattern-loaders.rb"
			file.puts "% See also http://tug.org/tex-hyphen"
			file.puts "%"
			file.puts "% Copyright 2008 TeX Users Group."
			file.puts "% You may freely use, modify and/or distribute this file."
			file.puts "% (But consider adapting the scripts if you need modifications.)"
			file.puts "%"
			file.puts "% Once it turns out that more than a simple definition is needed,"
			file.puts "% these lines may be moved to a separate file."
			file.puts "%"

			# message (where it exists)
			# if language.message != nil
			# 	file.puts("\\message{#{language.message}}\n%")
			# end
		
			# TODO:
			# \lefthyphenmin=2 \righthyphenmin=2
			# but probably this needs to reside outside of \begingroup/endgroup
			
			file.puts('\begingroup')
			if language.code == 'it' or language.code == 'fr' or language.code == 'uk' or language.code == 'la' or language.code == 'zh-latn' then
				file.puts("\\lccode`\\'=`\\'")
			end
			if language.code == 'pt' then
				file.puts("\\lccode`\\-=`\\-")
			end
			
			# some special cases firs
			#
			# some languages (sanskrit) are useless in 8-bit engines; we only want to load them for UTF engines
			# TODO - maybe consider doing something similar for ibycus
			if language.code == 'sa' then
				file.puts(text_if_native_utf)
				file.puts("    \\message{UTF-8 #{language.message}}")
				file.puts('    % Set \lccode for ZWNJ and ZWJ.')
				file.puts('    \lccode"200C="200C')
				file.puts('    \lccode"200D="200D')
				file.puts("    \\input hyph-#{language.code}.tex")
				file.puts('\else')
				file.puts("    \\message{No #{language.message} - only available with Unicode engines}")
				file.puts('    \input zerohyph.tex')
				file.puts('\fi')
			# for ASCII encoding, we don't load any special support files, but simply load everything
			elsif language.encoding == "ascii" then
				file.puts('% ASCII patterns - no additional support is needed')
				# for UK English we simply load the old file without bothering about renaming it
				if language.use_old_patterns then
					file.puts("\\input #{language.filename_old_patterns}")
				# for the rest we load the new file
				else
					file.puts("\\message{ASCII #{language.message}}")
					file.puts("\\input hyph-#{language.code}.tex")
				end
			# when lanugage uses old patterns for 8-bit engines, load two different patterns rather than using the converter
			elsif language.use_old_patterns then
				file.puts(text_if_native_utf)
				file.puts("    \\message{UTF-8 #{language.message}}")
				# some catcodes for XeTeX
				if language.code == 'grc' or language.code.slice(0,2) == 'el' then
					file.puts("    \\lccode`'=`'\\lccode`’=`’\\lccode`ʼ=`ʼ\\lccode`᾽=`᾽\\lccode`᾿=`᾿")
				end
				file.puts("    \\input hyph-#{language.code}.tex")
				# russian and ukrainian exceptions - hacks with dashes
				if language.code == 'ru' or language.code == 'uk' then
					file.puts('    % Additional patterns with hyphen/dash: a hack to prevent breaking after hyphen, but not before.')
					file.puts("    \\input exhyph-#{language.code}.tex")
				end
				file.puts('\else')
				file.puts("    \\message{#{language.message}}")
				# explain why we are still using the old patterns
				if language.use_old_patterns_comment != nil then
					file.puts("    % #{language.use_old_patterns_comment}")
				else
					puts "Missing comment for #{language.name}"
					file.puts('    % we still load old patterns for 8-bit TeX')
				end
				file.puts("    \\input #{language.filename_old_patterns}")
				file.puts('\fi')
			else
				file.puts(text_if_native_utf)
				file.puts("    \\message{UTF-8 #{language.message}}")
				file.puts('\else')
				file.puts("    \\message{#{language.encoding.upcase} #{language.message}}")
				# a hack for OT1 encoding in three languages
				if language.code == 'da' or language.code == 'fr' or language.code == 'la' then
					file.puts("    % A hack to support both EC and OT1 encoding in 8-bit engines.")
					file.puts("    % Kept for backward compatibility only, though we would prefer to drop it.")
					file.puts("    % OT1 encoding is close-to-useless for proper hyphenation.")
					file.puts("    \\input spechyph-ot1-#{language.code}.tex")
				end
				file.puts("    \\input conv-utf8-#{language.encoding}.tex")
				file.puts('\fi')
				if language.code == 'sr-latn' then
					file.puts("% Load Serbo-Croatian patterns")
					file.puts("\\input hyph-sh-latn.tex")
				else
					file.puts("\\input hyph-#{language.code}.tex")
				end
#				file.puts("\\loadhyphpatterns{#{language.code}}{#{language.encoding}}%")
			end
			file.puts('\endgroup')
		end
	end
end


