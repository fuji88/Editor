/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * controller_main.vala
 * Copyright (C) EasyRPG Project 2011
 *
 * EasyRPG is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * EasyRPG is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class MainController : Controller {
	/*
	 * Properties
	 */
	// Views
	private MainWindow main_view;

	// Models
	private Party party;
	private Vehicle boat;
	private Vehicle ship;
	private Vehicle airship;

	// Others
	private string game_title;
	private string base_path;
	private string project_filename;
	private XmlNode project_data;
	private XmlNode game_data;

	/*
	 * Constructor
	 */
	public MainController () {
		this.main_view = new MainWindow (this);
	}

	/*
	 * Run
	 */
	public override void run () {
		this.main_view.show_all ();
	}

	/*
	 * Open project
	 */
	public void open_project () {
		var open_project_dialog = new Gtk.FileChooserDialog ("Open Project", this.main_view,
		                                                     Gtk.FileChooserAction.OPEN,
		                                                     Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
		                                                     Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		/*
		 * FIXME
		 * FileFilter.set_filter_name is not implemented yet but will work soon.
		 * More info: https://bugzilla.gnome.org/show_bug.cgi?id=647122
		 * 
		 * Using proposed workaround "gtk_file_filter_set_name".
		 */
		var file_filter = new Gtk.FileFilter();
		//file_filter.set_name ("EasyRPG Project (*.rproject)");
		//file_filter.set_filter_name ("EasyRPG Project (*.rproject)");
		gtk_file_filter_set_name (file_filter, "EasyRPG Project (*.rproject)");
		file_filter.add_pattern ("*.rproject"); // for case-insensitive patterns -> add_custom()
		open_project_dialog.add_filter (file_filter);
		
		if (open_project_dialog.run () == Gtk.ResponseType.ACCEPT) {
			// Get the base_path and project_filename from the selected file
			string full_path = open_project_dialog.get_filename ();
			string[] path_tokens = full_path.split ("/");
			this.project_filename = path_tokens[path_tokens.length - 1];
			this.base_path = full_path.replace (this.project_filename, "");

			// Manages all the XML read stuff
			this.load_project_data ();

			/*
			 * Test: XML data loaded successfully?
			 */
			print ("********************************\n");
			print ("OPEN\n");
			print ("********************************\n");
			print ("Game title: %s\n", this.game_title);
			print ("Party data:\n");
			print ("  map_id: %i\n", this.party.map_id);
			print ("  x: %i\n", this.party.x);
			print ("  y: %i\n", this.party.y);
			print ("Boat data:\n");
			print ("  map_id: %i\n", this.boat.map_id);
			print ("  x: %i\n", this.boat.x);
			print ("  y: %i\n", this.boat.y);
			print ("Ship data:\n");
			print ("  map_id: %i\n", this.ship.map_id);
			print ("  x: %i\n", this.ship.x);
			print ("  y: %i\n", this.ship.y);
			print ("Airship data:\n");
			print ("  map_id: %i\n", this.airship.map_id);
			print ("  x: %i\n", this.airship.x);
			print ("  y: %i\n", this.airship.y);
			print ("Current scale: %i\n\n", this.main_view.get_current_scale ());

			// Enable/disable some ToolItems and MenuItems
			this.main_view.actiongroup_project_closed.set_sensitive (false);
			this.main_view.actiongroup_project_open.set_sensitive (true);
		}
		open_project_dialog.destroy ();
	}

	/*
	 * Load project data
	 */
	private void load_project_data () {
		XmlParser parser = new XmlParser ();
		
		// Load data from the .rproject file
		parser.parse_file (this.base_path + this.project_filename);
		this.project_data = parser.root;

		int current_map = int.parse (parser.get_node ("current_map").content);
		int current_scale = int.parse (parser.get_node ("current_scale").content);
		if (current_scale > 0 && current_scale < 4) {
			this.main_view.set_current_scale (current_scale);
		}

		// Load data from game.xml and instantiate the party and vehicles
		parser.parse_file (this.base_path + "data/game.xml");
		this.game_data = parser.root;

		XmlNode title_node = parser.get_node ("title");
		this.game_title = title_node.content;

		this.party = new Party ();
		XmlNode party_node = parser.get_node ("party");
		this.party.load_data (party_node);

		this.boat = new Vehicle ();
		XmlNode boat_node = parser.get_node ("boat");
		this.boat.load_data (boat_node);

		this.ship = new Vehicle ();
		XmlNode ship_node = parser.get_node ("ship");
		this.ship.load_data (ship_node);

		this.airship = new Vehicle ();
		XmlNode airship_node = parser.get_node ("airship");
		this.airship.load_data (airship_node);
	}

	/*
	 * Close project
	 */
	public void close_project () {
		// Properties change to null
		this.game_title = null;
		this.project_filename = null;
		this.base_path = null;
		this.project_data = null;
		this.game_data = null;

		this.party = null;
		this.boat = null;
		this.ship = null;
		this.airship = null;

		// Enable/disable some ToolItems and MenuItems
		this.main_view.actiongroup_project_open.set_sensitive (false);
		this.main_view.actiongroup_project_closed.set_sensitive (true);

		// Set default values for RadioActions and ToggleActions
		this.main_view.set_current_layer (0);
		this.main_view.set_current_scale (0);
		this.main_view.set_current_drawing_tool (2);
		var action_fullscreen = main_view.get_action_from_name("OpenGroup", "ActionFullScreen") as Gtk.ToggleAction;
		var action_title = main_view.get_action_from_name("OpenGroup", "ActionTitle") as Gtk.ToggleAction;
		action_fullscreen.set_active (false);
		action_title.set_active (false);

		/*
		 * Test: project is closed?
		 * 
		 * When a project is closed, all the data changes to null and the RadioActions
		 * change to the default value: Lower layer, 1/1 scale and Pencil tool. 
		 */
		print ("********************************\n");
		print ("CLOSED\n");
		print ("********************************\n");
		print ("Game title: %s\n", this.game_title ?? "null");		
		print ("Party: %s\n", this.party == null ? "null" : "exists");
		print ("Boat data: %s\n", this.boat == null ? "null" : "exists");
		print ("Ship data: %s\n", this.ship == null ? "null" : "exists");
		print ("Airship data: %s\n", this.airship == null ? "null" : "exists");
		print ("Current layer: %i (should be 0, lower layer)\n", this.main_view.get_current_layer ());
		print ("Current scale: %i (should be 0, 1/1 scale)\n", this.main_view.get_current_scale ());
		print ("Current drawing tool: %i (should be 2, pencil)\n", this.main_view.get_current_drawing_tool ());
	}

	/*
	 * Show database
	 */
	public void show_database () {
		var database_dialog = new DatabaseDialog (this);
		database_dialog.run ();
		database_dialog.destroy ();
	}

	/*
	 * On about
	 */
	public void on_about () {
		var about_dialog = new Gtk.AboutDialog ();
		about_dialog.set_transient_for (this.main_view);
		about_dialog.set_modal (true);
		about_dialog.set_version ("0.1.0");
		about_dialog.set_license_type (Gtk.License.GPL_3_0);
		about_dialog.set_program_name ("EasyRPG Editor");
		about_dialog.set_comments ("A role playing game editor");
		about_dialog.set_website ("http://easy-rpg.org/");
		about_dialog.set_copyright ("© EasyRPG Project 2011");

		const string authors[] = {"Héctor Barreiro", "Glynn Clements", "Francisco de la Peña", "Aitor García", "Gabriel Kind", "Alejandro Marzini http://vgvgf.com.ar/", "Shin-NiL", "Rikku2000 http://u-ac.net/rikku2000/gamedev/", "Mariano Suligoy", "Paulo Vizcaíno", "Takeshi Watanabe http://takecheeze.blog47.fc2.com/"};
		const string artists[] = {"Ben Beltran http://nsovocal.com/", "Juan «Magnífico»", "Marina Navarro http://muerteatartajo.blogspot.com/"};
		about_dialog.set_authors (authors);
		about_dialog.set_artists (artists);

		try {
			var logo = new Gdk.Pixbuf.from_file ("./share/easyrpg/icons/hicolor/48x48/apps/easyrpg.png");
			about_dialog.set_logo (logo);
		}
		catch (Error e) {
			stderr.printf ("Could not load about dialog logo: %s\n", e.message);
		}

		about_dialog.run ();
		about_dialog.destroy ();
	}
}

// Workaround
extern void gtk_file_filter_set_name (Gtk.FileFilter filter, string name);