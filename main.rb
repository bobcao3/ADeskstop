#!/bin/ruby
require 'gtk3'

module ADesktop

class MainWindow < Gtk::Window
	COL_PATH, COL_DISPLAY_NAME, COL_IS_DIR, COL_PIXBUF = (0..3).to_a
	 
	def fill_store
		@store.clear
		Dir.glob(File.join(@parent, "*")).each do |path|
        	is_dir = FileTest.directory?(path)
			
			iconfile = Gtk::IconTheme.default.lookup_icon("gtk-file", 48, 0).filename if !is_dir
			iconfile = Gtk::IconTheme.default.lookup_icon("folder", 48, 0).filename if is_dir
			
        	iter = @store.append
        	path = GLib.filename_to_utf8(path)
        	iter[COL_DISPLAY_NAME] = File.basename(path)
        	iter[COL_PATH] = path
        	iter[COL_IS_DIR] = is_dir
        	iter[COL_PIXBUF] = Gdk::Pixbuf.new(iconfile)
      	end
    end
	
	def initialize()
		super(:popup)
		set_title("ADesktop")
		self.signal_connect("destroy") {
			Gtk.main_quit
		}
		
		screen = Gdk::Screen.default
		self.set_default_size(screen.width,screen.height)
		self.skip_pager_hint = true
		self.skip_taskbar_hint = true
		
		@store = Gtk::ListStore.new(String, String, TrueClass, Gdk::Pixbuf)
		@parent = "/home/aosc/Desktop"
		
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
      	sw = Gtk::ScrolledWindow.new
      	sw.set_policy(:automatic, :automatic)
      	box.pack_end(sw, :expand => true, :fill => true, :padding => 0)
      	
      	iconview = Gtk::IconView.new(@store)
      	iconview.selection_mode = :multiple
      	iconview.text_column = COL_DISPLAY_NAME
      	iconview.pixbuf_column = COL_PIXBUF
      	iconview.signal_connect("item_activated") do |iview, path|
        	iter = @store.get_iter(path)
			system("xdg-open "+iter[COL_PATH])
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

