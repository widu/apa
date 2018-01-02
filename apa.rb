

require 'tk'
require 'tkextlib/tile'
# require 'tkextlib/bwidget'


#load "lib/RdfProcess.rb"
load "../rdf_process/lib/Rdf_Process.rb"
require 'rdf_process'
# load definition
# load 'process_definition.rb'
# load 'process_definition.rb'

proc = RdfProcess.new

class MethodLogger
	def log_method(klass, method_name, receiver)
		klass.class_eval do
			alias_method "#{method_name}_original", method_name
			define_method method_name do
				# puts "#{Time.now}: Called #{method_name}"
				send "#{method_name}_original"
				receiver.send(method_name)
			end
		end
	end
end

class Controller
	attr_reader :fresh_status, :komunikat, :proc_info, :progress, :save_variables
	attr_accessor :menu_bar, :proc_run_proces, :file_menu_bar
	def initialize(proc, f_variable)
		@save_variables = 'no'
		@fresh_status =  TkVariable.new
		@komunikat = TkVariable.new
		@progress = TkVariable.new
		@progress.value = 0
		@proc_info = TkVariable.new
		@proc_info.value = "Open process!"
		@proc = proc
		@proc_widgets = []
		@proc_trigger_widget = nil
		@f_file = TkFrame.new(f_variable) do
     	 pack("side" => "left", 'fill' => 'y', 'expand' => 1, 'padx'  => 5,'pady'  => 5)
		end
		@f_run_process = TkFrame.new(f_variable) do
		 relief  'raised'
		 background 'grey25'
		 borderwidth 1
     	 pack("side" => "left", 'fill' => 'y', 'expand' => 1, 'padx'  => 5,'pady'  => 5)
		end
		@f_runtime_variable = TkFrame.new(f_variable) do
     	 pack("side" => "left", 'fill' => 'y', 'expand' => 1, 'padx'  => 5,'pady'  => 5)
		end
		@f_run_process_up = TkFrame.new(@f_run_process) do
			background 'grey25'
     	 pack("side" => "top", 'fill' => 'y', 'expand' => 1, 'padx'  => 10,'pady'  => 5)
		end
		@f_run_process_middle = TkFrame.new(@f_run_process) do
			background 'grey25'
     	 pack("side" => "top", 'fill' => 'y', 'expand' => 1, 'padx'  => 10,'pady'  => 5)
		end
		@f_run_process_bottom = TkFrame.new(@f_run_process) do
			background 'grey25'
     	 pack("side" => "top", 'fill' => 'y', 'expand' => 1, 'padx'  => 10,'pady'  => 5)
		end
		ent_graphviz_filtr = TkEntry.new(@f_run_process_up) do
			state   'readonly'
			readonlybackground 'grey25'
			foreground 'white'
			justify 'center'
      		width	5
         pack('padx'  => 5,
              'pady'  => 5,
              'side'  => 'left')
   		end
    	ent_graphviz_filtr.textvariable =  @fresh_status

		# @image_run = TkPhotoImage.new
  #   	@image_run.file = "run.gif"
	end
	def disp_fresh_status
		# menu save variables
		if @save_variables == 'no' then
			@file_menu_bar.entryconfigure 3, {:state => "disabled"} 
		else
			@file_menu_bar.entryconfigure 3, {:state => "active"} 
		end


		@fresh_status.value = @proc.fresh_status
		if @proc.fresh_status == 'old' then
			begin
				@menu_bar.delete(2)
				@run_button.destroy
			rescue
			end
			@menu_bar.add('command',
             	'label' => "Run Process",
            	 'command'   => @proc_run_proces,
            	 'underline' => 0
            	 )
			image_run = TkPhotoImage.new
    		image_run.file = "icons/run.gif"
    		# image_run.scale 20
    		# image_run['width'] = 20
    		# image_run['height'] = 20
    		proc1 = @proc_run_proces
    		@run_button = TkButton.new(@f_run_process_middle) do
    		  text "Run Process" 
    		  # command proc_set_runtime_variable
    		  background   "red"
    		  image   image_run
    		  command proc1
    		  pack( "side" => "top")
    		end
		else
			@menu_bar.delete(2)
			image_run = TkPhotoImage.new
			image_run.file = "icons/pause.gif"
			@run_button.configure('image', image_run)
			@run_button.configure('background', 'grey85')
		end
	end
	def reset_process
		@proc.reset
	end
	def disp_process
		@proc_widgets.each do | widget |
			widget.destroy
		end

 		@proc.runtime_variable_list.each do | key,  runtime_variable |
 			if runtime_variable[:type] == "filtr" then
 			f = TkFrame.new(@f_runtime_variable) do
 				relief 'groove'
 				borderwidth 1
 				padx 10
  				pady 10
 			    pack("side" => "top", 'fill' => 'x')
 			end
 			@proc_widgets << f
 			f1 = TkFrame.new(f) do
      			pack("side" => "left")
			end
			f2 = TkFrame.new(f) do
      			pack("side" => "left")
			end
 			image = TkPhotoImage.new
			image.file = "icons/search.gif"
 			TkLabel.new(f2) {
     			# text    runtime_variable[:value]
     			text    "Filtr: " + key
     			# bitmap  'bi1.bmp' error, gray12, gray25, gray50, gray75, hourglass, info, question, questhead, warning
      			# image   image
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'top')
    		}
    		TkButton.new(f2) do
    		  text "Change filtr: " + key
    		  # command proc_set_runtime_variable
    		  image   image
    		  command '$cntrl.edit_filtr("' + key + '")'
    		  pack( "side" => "top")
    		
    		end
    		image2 = TkPhotoImage.new
    		image2.file = "icons/arrow.gif"
    		TkLabel.new(f1) {
     			image   image2
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'top')
    		}

    		# zmienne zależne
    		f3 = TkFrame.new(f) do
      			pack("side" => "left")
			end
			@container = {}
    		dependent_steps = @proc.get_dependent_step_from(runtime_variable[:step_id])
    		dependent_steps.each do | step | 
    			@container[step] = TkFrame.new(f3) do
      				pack("side" => "top")
				end
    		end

    	elsif runtime_variable[:type] == "input_file" then


    		f = TkFrame.new(@f_file) do
 				relief 'groove'
 				borderwidth 1
 				padx 10
  				pady 10
 			    pack("side" => "top", 'fill' => 'x')
 			end
 			@proc_widgets << f
 			f1 = TkFrame.new(f) do
      			pack("side" => "left")
			end
			f2 = TkFrame.new(f) do
      			pack("side" => "left")
			end
 			image = TkPhotoImage.new
			image.file = "icons/file.gif"
			res = /.+\/(.+\.\w+)$/.match runtime_variable[:value]
 			TkLabel.new(f1) {
     			text    $1
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'top')
    		}
    		TkButton.new(f1) do
    		  text "Change filtr: " 
    		  # command proc_set_runtime_variable
    		  image   image
    		  command  '$cntrl.set_monitor_file("' + key + '")'
    		  pack( "side" => "top")
    		
    		end
    		image2 = TkPhotoImage.new
    		image2.file = "icons/arrow.gif"
    		TkLabel.new(f2) {
     			image   image2
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'top')
    		}

    	elsif runtime_variable[:type] == "output_file" then
    		frm_step = @container[runtime_variable[:step_id]]
    		frm = TkFrame.new(frm_step) do
      			pack("side" => "left")
			end
    		image = TkPhotoImage.new
			image.file = "icons/save.gif"
			res = /.+\/(.+\.\w+)$/.match runtime_variable[:value]
			if $1 == nil then
				txt1 = runtime_variable[:value]
			else
				txt1 = $1
			end
 			TkLabel.new(frm) {
     			text    txt1
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'top')
    		}
    		TkButton.new(frm) do
    		  text "Change filtr: " 
    		  # command proc_set_runtime_variable
    		  image   image
    		  command  '$cntrl.set_output_file_variable("' + key + '")'
    		  pack( "side" => "top")
    		
    		end
    		frm2 = TkFrame.new(frm_step) do
      			pack("side" => "left", 'fill' => 'y')
			end
    		image2 = TkPhotoImage.new
			image2.file = "icons/watch.gif"
			puts  "system( 'start " + runtime_variable[:value] + "' )"
			TkButton.new(frm2) do
    		  text "Change filtr: " 
    		  # command proc_set_runtime_variable
    		  image   image2
    		  command  "system( 'start " + runtime_variable[:value] + "' )"
    		  pack( "side" => "bottom")
    		
    		end
    	end
 		end
	end
	def load_process(file)
		@file = file
		reset_process
		# load file
		# initialize_proc(@proc)
		@proc.eval_file(file)
		# należy usunąć z frama stary proces
		# @proc.fresh_status = 'old'
		@proc_info.value = "Process: #{file} - Steps: #{@proc.runtime_list.size}"
		file.gsub!(/\.\w+$/, ".variables")
		

		disp_process

		@proc.eval_file(file) if File::exists?( file )

		disp_fresh_status
	end
	def run_process
		image_run = TkPhotoImage.new
		image_run.file = "icons/think.gif"
		@run_button.configure('image', image_run)
		@run_button.configure('background', 'grey85')
		Tk.update_idletasks

		@proc.processing
		# graphviz_filtr_value.value = proc.fresh_status
		disp_fresh_status
		# menu_bar.activate(1)
		# @menu_bar.delete(2)
	end
	def set_runtime_variable(name, value)
		@save_variables = 'yes'
		@proc.set_runtime_variable(name, value)
		disp_fresh_status

	end
	def add_trigger_widget(menu_bar, proc_run_proces)
				@proc_trigger_widget = menu_bar.add('command',
             	'label' => "Run Process",
            	 'command'   => proc_run_proces,
            	 'underline' => 0
            	 )
	end
	def edit_filtr(variable1)
		 begin
    		$win.destroy
    	  rescue
    	  end
    	  $win = TkToplevel.new
    	  $win.raise_window $root
    	  $win.transient $root
    	  $win.title = variable1
    	  @template_text = ''
    	  @parameter_combo_list = []
    	  $queryvar_hash = {}
    	  # $root['state'] = 'withdrawn'
    	  if @proc.runtime_variable_list['res2'][:value] then

    	  	# prefix = "PREFIX rdf:      <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    	  	# PREFIX rdfs: 	<http://www.w3.org/2000/01/rdf-schema#>
    	  	# PREFIX owl:  <http://www.w3.org/2002/07/owl#>
    	  	# PREFIX wdc:     <http://vieslav.pl/csv/0.1/> \n"
    	  	prefix = @proc.runtime_variable_list["prefix"][:value]

    	  	# Query list
    	  	rdf_query = prefix + "SELECT ?q_name ?qr 
    	  	WHERE { ?ql a wdc:Query .
    	  	?ql wdc:Name ?q_name .
    	  	?ql wdc:Query ?qr .}
    	  	ORDER BY ?q_name"
    	  	@result = SPARQL.execute(rdf_query, @proc.runtime_variable_list['res2'][:value])
    	  	lista_q = []
    	  	puts @result
			@result.each { |solution| 
				solution.each_binding    { |name, value| 
					puts "name: #{name}, value: #{value}"
					if name.to_s == 'q_name' then
						lista_q << value 
					end
			 }}

    	  	$queryvar = TkVariable.new
    	 	$queryvar.value = "Choice query"
		  	combo_query = Tk::Tile::Combobox.new($win) { 
		  		textvariable $queryvar
		  		values lista_q
		  		pack("side" => "top", 'fill' => 'both') }

		  	# parameters frame		
    	  	@frm_parameters = TkFrame.new($win) do
      			pack("side" => "top", 'fill' => 'both')
			end

		  	combo_query.bind("<ComboboxSelected>") {  
		  		#res = @result.filter { |solution| solution.q_name.to_s == $queryvar.value }
		  		@result.each { |solution| 
		  			#puts solution.inspect 
		  			if solution.q_name.to_s == $queryvar.value then
		  				$text.delete(1.0, 'end')
		  				@template_text = solution.qr.to_s
		  				$text.insert 'end', solution.qr.to_s
		  			end

		  			puts solution.qr.to_s
		  			puts $queryvar.value
		  		}

		  		# param
		  		@parameter_combo_list.each do | widget |
						widget.destroy
				end
				@parameter_combo_list = []

		  		rdf_query = prefix + "SELECT ?Parameter ?Query
			  			WHERE 
			  			{ 
			  			 ?QueryRelation wdc:Query \"#{$queryvar.value}\" .
			  			 ?QueryRelation a wdc:QueryRelation .
			  			 ?QueryRelation wdc:Parameter ?Parameter .
			  			 ?QueryRelation wdc:ParameterValueID ?ParameterValueID .
			  			 ?QueryParameterValue wdc:ParameterValueID ?ParameterValueID .
			  			 ?QueryParameterValue a wdc:QueryParameterValue .
			  			 ?QueryParameterValue wdc:Query ?Query .
 			 			 }"
		  			
		  		result = SPARQL.execute(rdf_query, @proc.runtime_variable_list['res2'][:value])

		  		result.each { |solution|
		  			puts "Parameter #{solution.Parameter.to_s}"
		  			puts solution.Query.to_s
		  			rdf_query = prefix + solution.Query.to_s
		  			result2 = SPARQL.execute(rdf_query, @proc.runtime_variable_list['res2'][:value])
		  			lista_q2 = []

		  			result2.each { |solution| 
						solution.each_binding    { |name, value| 
							
							lista_q2 << value 
							
			 		}}
			 		puts lista_q2
			 		$queryvar_hash[solution.Parameter.to_s] = TkVariable.new
			 		$queryvar_hash[solution.Parameter.to_s].value = "Choice: #{solution.Parameter.to_s}"
			 		combo_query2 = Tk::Tile::Combobox.new(@frm_parameters) { 
		  				textvariable $queryvar_hash[solution.Parameter.to_s]
		  				values lista_q2
		  				pack("side" => "top", 'fill' => 'both') }
		  			@parameter_combo_list << combo_query2

		  			combo_query2.bind("<ComboboxSelected>") {  
		  				thetext = @template_text.gsub "$#{solution.Parameter.to_s}$", $queryvar_hash[solution.Parameter.to_s].value
		  				$text.delete(1.0, 'end')
		  				
		  				$text.insert 'end', thetext  }
		  		}

					# parameters combobox______________________________________________________________


					# rdf_query = prefix + "SELECT ?ObjectName
			  # 			WHERE 
			  # 			{ ?object a wdc:SubEpic .
			  # 			 ?object wdc:Name ?ObjectName .
 			 # 			 }"

 			 # 		@result2 = SPARQL.execute(rdf_query, @proc.runtime_variable_list['res2'][:value])
    	#   			lista_q = []
    	#   			puts @result2

					# @result2.each { |solution| 
					# 	solution.each_binding    { |name, value| 
					# 		puts "name: #{name}, value: #{value}"
							
					# 		lista_q << value 
							
			 	# 	}}

					# $queryvar2 = TkVariable.new
    	#  			$queryvar2.value = "Choice parameter value"
		  	# 		combo_query2 = Tk::Tile::Combobox.new(@frm_parameters) { 
		  	# 			textvariable $queryvar2
		  	# 			values lista_q
		  	# 			pack("side" => "top", 'fill' => 'both') }		
		  	# 		@parameter_combo_list << combo_query2
		  	# 		combo_query2.bind("<ComboboxSelected>") {  
		  	# 			puts @template_text
		  	# 			thetext = @template_text.gsub '$subEpicName$', $queryvar2.value
		  	# 			$text.delete(1.0, 'end')
		  				
		  	# 			$text.insert 'end', thetext  }
		  		}

		  		
    	  end

    	  
    	 
    	  $text = TkText.new($win) do
    	    width 40
    	    height 20
    	    borderwidth 1
    	    # font TkFont.new('times 12 bold')
    	    pack("side" => "top",  "padx"=> "5", "pady"=> "5", 'fill' => 'both', 'expand' => 1)
    	  end

    	  

    	  $text.insert 'end', @proc.runtime_variable_list[variable1][:value]
    	  f_1 = TkFrame.new($win) do
    	  	background 'grey25'
         	pack("side" => "top", 'fill' => 'x', 'expand' => 1)
		 end
		image_ok = TkPhotoImage.new
		image_ok.file = "icons/ok_small.gif"
    	  TkButton.new(f_1) {
    		text 'Change'
    		image image_ok
    		command '$cntrl.save_filtr("' + variable1 + '",$text.get("1.0", "end"))'
    		pack("side" => "right", "padx"=> "5", "pady"=> "5")
    	  }
    	image_cancel = TkPhotoImage.new
		image_cancel.file = "icons/cancel_small.gif"
    	  TkButton.new(f_1) {
    		text 'Cancel'
    		image image_cancel
    		command '$win.destroy'
    		pack("side" => "right", "padx"=> "5", "pady"=> "5")
    	  }
	end
	def save_filtr(name, value)
		set_runtime_variable(name, value)
		disp_process
		$win.destroy
	end
	def set_monitor_file(name)
		file = Tk.getOpenFile
		puts name
		if file != ""
		 	set_runtime_variable(name, file)
			# @proc.set_monitor_file(index, file)
			disp_process
		end 
		
	end
	def set_output_file_variable(name)
		file = Tk.getSaveFile
		puts name
		if file != ""
			set_runtime_variable(name, file)
			# @proc.set_monitor_file(index, file)
			disp_process
		end
	end
	def repeat_every(interval, menu_bar, proc_run_proces)
	  Thread.new do
	    loop do
	      start_time = Time.now
	      
	      # sprawdzanie aktualności zmiennych plikowych
	      @proc.runtime_variable_list.each do | key,  runtime_variable |
 			if runtime_variable[:type] == "input_file" then
 				t = File::mtime( runtime_variable[:value] )
 				if runtime_variable[:mtime] == nil then
 					runtime_variable[:mtime] = t
 				else
 					if runtime_variable[:mtime] == t then
 					else
 						puts "Zmiana: #{t}"
 						runtime_variable[:mtime] = t
 						@proc.refresh_status(runtime_variable[:step_id])
 						@proc.fresh_status = "old"
 						disp_fresh_status
 						disp_komunikat "File: #{runtime_variable[:value]} was changed! Run process again!"

 						# puts @proc.runtime_list
 					end

	      		end
	      	end
	      end

	      elapsed = Time.now - start_time
	      sleep([interval - elapsed, 0].max)
	    end
	  end
	end
	def disp_komunikat(komunikat, progress = nil)
		@komunikat.value = komunikat
		if progress != nil then
			@progress.value = progress
		end
		Tk.update_idletasks
	end

	def send_log
		disp_komunikat(@proc.komunikat, @proc.progress) 
	end

	def save_variable
		file = @file.gsub(/\.\w+$/, ".variables")
		@proc.save_variables(file)
		@save_variables = 'no'
		disp_fresh_status
	end

end





#uruchomienie procesu
# proc.processing


# gui
image_run = TkPhotoImage.new
image_run.file = "icons/apa.gif"
root = TkRoot.new do
	minsize(200,200) 
	resizable(false, false)
	iconphoto image_run
end
root.title = "APA"

$root = root

f1 = TkFrame.new(root) do
      pack("side" => "top", 'fill' => 'y', 'expand' => 0)
end

f_title = TkFrame.new(f1) do
	background 'grey25'
      pack("side" => "top", 'fill' => 'both', 'expand' => 1)
end

think_mini = TkPhotoImage.new
think_mini.file = "icons/inf_mini1.gif"
TkLabel.new(f_title) {
     			image   think_mini
     			background 'grey25'
      			pack('padx'  => 5,
          		 'pady'  => 5,
          		 'side'  => 'left')
    		}

proc_info = TkLabel.new(f_title) {
     			text    "komunikat"
     			background 'grey25'
     			# foreground 'grey85'
     			foreground  'white'
     			wraplength  700
      			pack('padx'  => 5,
          		 'pady'  => 2,
          		 'side'  => 'left')
    		}


f_variable = TkFrame.new(f1) do
      pack("side" => "top", 'fill' => 'y', 'expand' => 1)
end

f_stopka = TkFrame.new(f1) do
	# background 'grey25'
    pack("side" => "top", 'fill' => 'both', 'expand' => 1)
end
f_stopka_left = TkFrame.new(f_stopka) do
	background 'grey25'
	width 50
    pack("side" => "left",'fill' => 'y' , 'expand' => 0)
end
f_stopka_center = TkFrame.new(f_stopka) do
	background 'grey25'
	# with 30
    pack("side" => "left", 'padx'  => 2, 'fill' => 'both', 'expand' => 1)
end
f_stopka_right = TkFrame.new(f_stopka) do
	background 'grey25'
	width 450
    pack("side" => "left", 'fill' => 'y', 'expand' => 0)
end

kom = TkLabel.new(f_stopka_center) {
     			text    "komunikat"
     			background 'grey25'
     			foreground 'grey85'
     			# wraplength  700
      			pack('padx'  => 5,
          		 'pady'  => 2,
          		 'side'  => 'left')
    		}



    	p = Tk::Tile::Progressbar.new(f_stopka_right) {
    		orient 'horizontal'; 
    		length 80; 
    		mode 'determinate'
    		maximum  100
    		# foreground 'white'
    		# colors  ['red']
    	}
    	
        p.pack("side" => "left", 'padx'  => 2)

        prog_label = TkLabel.new(f_stopka_right) {
     			text    "0"
     			background 'grey25'
     			foreground 'grey85'
     			# wraplength  700
      			pack('padx'  => 5,
          		 'pady'  => 2,
          		 'side'  => 'left')
    		}
    	
        prog_label.pack("side" => "right")

# $province = TkVariable.new ( "" );
# cbox = Tk::Tile::Combobox.new(f_stopka) {
# 	state  'readonly'
# 	background 'grey25'
# 	# readonlybackground  'grey25'
# 	width  70
# 	textvariable $province
# 	values ['message 1 ......', 'message 2 ...', 'message 3 ...']
# }
# cbox.pack("side" => "right")


controller = Controller.new(proc, f_variable)

# monitorowanie procesu
logger = MethodLogger.new
logger.log_method(RdfProcess, :send_log, controller)

$cntrl = controller
# proc.komunikat = controller
kom.textvariable =  controller.komunikat
proc_info.textvariable = controller.proc_info
p.variable = controller.progress
prog_label.textvariable = controller.progress

# obsługa zdarzeń TK
proc_open_proces = Proc.new {
	# proc.reset
	
	file = Tk.getOpenFile
	# load 'process_definition.rb'
	if file != ""
		controller.load_process(file)
	end
	
	
}

proc_save_proces = Proc.new {

	controller.save_variable
}

menu_bar = TkMenu.new
controller.menu_bar = menu_bar
graphviz_filtr_value = TkVariable.new



proc_run_proces = Proc.new {

	controller.run_process	
}
$cntrl.proc_run_proces = proc_run_proces

#monit
thread = controller.repeat_every(5, menu_bar, proc_run_proces) 

# proc_set_runtime_variable = Proc.new {
# 	controller.set_runtime_variable("filtr1", "CONSTRUCT {  
# ?Makieta wdc:MapujeSieNa ?Map .
# ?Map wdc:DotyczyZrodlaDanych ?ZD .
#  } 
# WHERE {  
# ?Makieta wdc:MapujeSieNa ?Map . 
# ?Map wdc:DotyczyZrodlaDanych ?ZD .
# ?Map wdc:Makieta 'Historia wplat mobile' .
# ?Map wdc:Sekcja 'Okno modalne - Faktura' .
# }")
# 	controller.add_trigger_widget(menu_bar, proc_run_proces)
# }

proc_exit = Proc.new {
	puts "exit apa"
	if controller.save_variables == 'yes' then
	 if Tk::messageBox( :type => 'yesno', 
	    :message => 'Do you want save process variables?', 
	    :icon => 'question', :title => 'Save variables') == "yes" then
	    controller.save_variable
	    puts "saved"
	 end
	end 
	# thread.join
	Thread.kill(thread)
	exit
}



file_menu = TkMenu.new(root)
controller.file_menu_bar = file_menu

file_menu.add('command',
              'label'     => "Open process...",
              'command'   => proc_open_proces,
              'underline' => 0)
file_menu.add('separator')
file_menu.add('command',
              'label'     => "Save variables...",
              'command'   => proc_save_proces,
              'underline' => 0)
file_menu.add('separator')             
file_menu.add('command',
              'label'     => "Exit",
              'command'   => proc_exit,
              'underline' => 3)


menu_bar.add('cascade',
             'menu'  => file_menu,
             'label' => "File")




root.menu(menu_bar)
# wm resizable root 0 0
file_menu.entryconfigure 3, {:state => "disabled"} 

root.protocol "WM_DELETE_WINDOW", proc_exit

Tk.mainloop

