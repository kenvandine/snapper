/*
 * Copyright (C) 2018 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class InstalledPage : Gtk.ScrolledWindow
{
    public signal void select_app (App app);

    private Gtk.ListBox app_list;

    public InstalledPage ()
    {
        set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);

        app_list = new Gtk.ListBox ();
        app_list.visible = true;
        app_list.margin = 12;
        app_list.activate_on_single_click = true;
        app_list.selection_mode = Gtk.SelectionMode.NONE;
        app_list.set_sort_func ((row1, row2) => {
            var app1 = ((AppRow) row1).app;
            var app2 = ((AppRow) row2).app;
            return strcmp (app1.title.casefold (), app2.title.casefold ());
        });
        app_list.row_activated.connect ((row) => { select_app (((AppRow) row).app); });
        add (app_list);
    }

    public void add_app (App app)
    {
        var row = new AppRow (app);
        row.visible = true;
        row.margin = 6;
        app_list.add (row);
    }
}
