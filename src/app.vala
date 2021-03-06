/*
 * Copyright (C) 2018 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class App : Object
{
    public virtual string title { get { return ""; } }
    public virtual string publisher { get { return ""; } }
    public virtual string publisher_id { get { return ""; } }
    public virtual bool publisher_validated { get { return false; } }
    public virtual string summary { get { return ""; } }
    public virtual string description { get { return ""; } }
    public virtual string? icon_url { get { return ""; } }
    public virtual uint64 download_size { get { return 0; } }
    public virtual bool is_installed { get { return false; } }
    public virtual double progress { get { return -1.0; } }
    public virtual string? odrs_id { get { return null; } }

    public signal void changed ();
    public signal void progress_changed ();

    public App ()
    {
    }

    public virtual string[] get_tracks ()
    {
        return new string[0];
    }

    public virtual string? get_channel_version (string track, string risk, string? branch = null) {
        return null;
    }

    public virtual string[] get_screenshots ()
    {
        return new string[0];
    }

    public virtual async void install (Cancellable? cancellable = null)
    {
    }

    public virtual async void remove (Cancellable? cancellable = null)
    {
    }
}
