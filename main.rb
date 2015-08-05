#!/bin/ruby
require 'gtk3'

module ADesktop

class MainWindow < Gtk::Window
	COL_PATH, COL_DISPLAY_NAME, COL_IS_DIR, COL_PIXBUF = (0..3).to_a
	 
	def find_file(basename)
		%w(./ /usr/share/gtk-3.0/demo /usr/share/icons/Numix-Circle-Light/scalable/apps/).each do |dirname|
			path = dirname + basename
			if File.exist?(path)
				return path
			end
		end
		
    	return "./gnome-fs-regular.png"
  	end
	 
	def fill_store
		@store.clear
		Dir.glob(File.join(@parent, "*")).each do |path|
        	is_dir = FileTest.directory?(path)
        	if !is_dir
        		file = File.open(path) 
        		fname = false
        		ficon = false
        		fexec = false
				while line  = file.gets
        			case line.split("=")[0]
        			when "Name"
        				name = line.split("=")[1]
        				fname = true
        			when "Icon"
        				foo = line.split("=")
        				bar = foo[1]
        				bar[-1] = "."
        				icon = find_file(bar + "svg")
        				ficon = true
        			when "Exec"
        				exec = line.split("=")[1]
        				fexec = true
        			end
        			if fname&&fexec&&ficon
        				break
        			end
				end
				if name==nil
					name = File.basename(path, ".desktop")
				end
			else
				name = File.basename(path)
			end
			
			if icon.to_s==''
				icon = "./gnome-fs-regular.png"
			end
			icon_px = Gdk::Pixbuf.new(icon) if !is_dir
			icon_px = @file_pixbuf if icon == nil
			icon_px = @folder_pixbuf if is_dir
			
        	iter = @store.append
        	path = GLib.filename_to_utf8(path)
        	iter[COL_DISPLAY_NAME] = name
        	iter[COL_PATH] = path
        	iter[COL_IS_DIR] = is_dir
        	iter[COL_PIXBUF] = icon_px
      	end
    end
	
	def initialize()
		super(:toplevel)
		set_title("ALaunch")
		self.signal_connect("destroy") {
			Gtk.main_quit
		}
		
		self.fullscreen
		
		@file_pixbuf = Gdk::Pixbuf.new("gnome-fs-regular.png")
      	@folder_pixbuf = Gdk::Pixbuf.new("gnome-fs-directory.png")
		
		@store = Gtk::ListStore.new(String, String, TrueClass, Gdk::Pixbuf)
		@parent = "/usr/share/applications/"
		
		@store.set_default_sort_func do |a, b|
        	if !a[COL_IS_DIR] and b[COL_IS_DIR]
        	  	1
        	elsif a[COL_IS_DIR] and !b[COL_IS_DIR]
        	  	-1
        	else
        	  	a[COL_DISPLAY_NAME] <=> b[COL_DISPLAY_NAME]
        	end
      	end
      	@store.set_sort_column_id(Gtk::TreeSortable::DEFAULT_SORT_COLUMN_ID, Gtk::SortType::ASCENDING)
      	fill_store
      	set_border_width(0)
      	
      	box = Gtk::Box.new(:vertical,0)
      	self.add(box)
      	
      	fixed = Gtk::Fixed.new()
      	button_exit = Gtk::Button.new(:label => "Back", :mnemonic => nil, :stock_id => nil)
      	button_exit.signal_connect("clicked") {
      		Gtk.main_quit()
      	}
      	fixed.add(button_exit)
      	box.pack_start(fixed, :expand => false, :fill => false, :padding => 0)
      	
      	sw = Gtk::ScrolledWindow.new
      	sw.set_policy(:automatic, :automatic)
      	box.pack_end(sw, :expand => true, :fill => true, :padding => 0)
      	
      	iconview = Gtk::IconView.new(@store)
      	iconview.item_orientation = :horizontal
      	iconview.activate_on_single_click = true
      	iconview.selection_mode = :single
      	iconview.text_column = COL_DISPLAY_NAME
      	iconview.pixbuf_column = COL_PIXBUF
      	iconview.signal_connect("item_activated") do |iview, path|
        	iter = @store.get_iter(path)
			if File.ftype(iter[COL_PATH]) != "directory"
				system("gtk-launch "+File.basename(iter[COL_PATH]))
				Gtk.main_quit
        	elsif iter[COL_DISPLAY_NAME]
          		@parent = iter[COL_PATH]
          		fill_store
        	end
      	end
      	
      	sw.add(iconview)
      	iconview.grab_focus
      	
      	provider = Gtk::CssProvider.new
      	cssfile = File.open("./style.css")
      	css=""
      	while line = cssfile.gets
      		css+=line
      	end
      	provider.load(:data => css)
      	apply_css(self, provider)
	end

	def apply_css(widget, provider)
    	widget.style_context.add_provider(provider, GLib::MAXUINT)
    	if widget.is_a?(Gtk::Container)
    		widget.each_forall do |child|
        		apply_css(child, provider)
        	end
        end
    end
    
end

end

Gtk.init
@window = ADesktop::MainWindow.new()
@window.show_all
Gtk.main

