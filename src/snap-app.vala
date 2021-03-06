/*
 * Copyright (C) 2018 Canonical Ltd.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class SnapApp : App
{
    public override string title {
        get {
            if (local_snap != null)
                return get_title (local_snap);
            else if (store_snap != null)
                return get_title (store_snap);
            else
                return "";
        }
    }
    private unowned string get_title (Snapd.Snap snap)
    {
        if (snap.title != null)
            return snap.title;
        else
            return snap.name;
    }
    public override string publisher {
        get {
            if (local_snap != null)
                return local_snap.publisher_display_name;
            else if (store_snap != null)
                return store_snap.publisher_display_name;
            else
                return "";
        }
    }
    public override string publisher_id {
        get {
            if (local_snap != null)
                return local_snap.publisher_username;
            else if (store_snap != null)
                return store_snap.publisher_username;
            else
                return "";
        }
    }
    public override bool publisher_validated {
        get {
            if (local_snap != null)
                return local_snap.publisher_validation == Snapd.PublisherValidation.VERIFIED;
            else if (store_snap != null)
                return store_snap.publisher_validation == Snapd.PublisherValidation.VERIFIED;
            else
                return false;
        }
    }
    public override string summary {
        get {
            if (local_snap != null)
                return local_snap.summary;
            else if (store_snap != null)
                return store_snap.summary;
            else
                return "";
        }
    }
    public override string description {
        get {
            if (local_snap != null)
                return local_snap.description;
            else if (store_snap != null)
                return store_snap.description;
            else
                return "";
        }
    }
    public override string? icon_url {
        get {
            if (local_snap != null && local_snap.icon != null)
                return local_snap.icon;
            if (store_snap != null && store_snap.icon != null)
                return store_snap.icon;
            return null;
        }
    }
    public override bool is_installed {
        get { return local_snap != null; }
    }
    public override double progress {
        get { return _progress; }
    }

    private Snapd.Snap? local_snap;
    private Snapd.Snap? store_snap;
    private double _progress = -1.0;

    public SnapApp (string name, Snapd.Snap? local_snap = null, Snapd.Snap? store_snap = null)
    {
        if (local_snap == null)
            load_local_metadata.begin (name);
        else
            this.local_snap = local_snap;
        if (store_snap == null)
            load_store_metadata.begin (name);
        else
            this.store_snap = store_snap;
    }

    public override string[] get_tracks () {
        if (store_snap == null)
            return new string[0];

        return store_snap.get_tracks ();
    }

    public override string? get_channel_version (string track, string risk, string? branch = null) {
        if (store_snap == null)
            return null;

        var channels = store_snap.get_channels ();
        for (var i = 0; i < channels.length; i++) {
            var channel = channels[i];
            if (channel.get_track () == track && channel.get_risk () == risk && channel.get_branch () == branch)
                return channel.version;
        }

        return null;
    }

    public override string[] get_screenshots ()
    {
        if (store_snap == null)
            return new string[0];

        var screenshots = store_snap.get_screenshots ();
        string[] urls = {};
        for (var i = 0; i < screenshots.length; i++) {
            var url = screenshots[i].url;
            var basename = Path.get_basename (url);
            if (basename == "banner.png" || basename == "banner.jpg" || basename == "banner-icon.png" || basename == "banner-icon.jpg" ||
                ((basename.has_prefix ("banner-icon_") || basename.has_prefix ("banner_")) && (basename.has_suffix (".png") || basename.has_suffix (".jpg"))))
                continue;
            urls += screenshots[i].url;
        }

        return urls;
    }

    public override async void install (Cancellable? cancellable = null)
    {
        var client = new Snapd.Client ();
        try {
            yield client.install2_async (Snapd.InstallFlags.NONE, store_snap.name, null, null, progress_cb, cancellable);
        }
        catch (Error e) {
            warning ("Failed to install %s: %s", store_snap.name, e.message);
            return;
        }

        try {
            local_snap = client.list_one_sync (store_snap.name);
        }
        catch (Error e) {
            warning ("Failed to get installed state for snap %s: %s", store_snap.name, e.message);
        }

        changed ();
    }

    public override async void remove (Cancellable? cancellable = null)
    {
        var client = new Snapd.Client ();
        try {
            yield client.remove_async (local_snap.name, progress_cb, cancellable);
        }
        catch (Error e) {
            warning ("Failed to remove %s: %s", store_snap.name, e.message);
            return;
        }
        local_snap = null;

        changed ();
    }

    private void progress_cb (Snapd.Client client, Snapd.Change change, void* deprecated)
    {
        var tasks = change.get_tasks ();
        int64 progress_done = 0;
        int64 progress_total = 0;
        for (var i = 0; i < tasks.length; i++) {
            progress_done += tasks[i].progress_done;
            progress_total += tasks[i].progress_total;
        }
        _progress = (double) progress_done / progress_total;
        progress_changed ();
    }

    private async void load_local_metadata (string name)
    {
        var client = new Snapd.Client ();
        try {
            local_snap = yield client.list_one_async (name, null);
            changed ();
        }
        catch (Error e) {
            if (!(e is Snapd.Error.NOT_FOUND))
                warning ("Failed to load local information on %s: %s", name, e.message);
        }
    }

    private async void load_store_metadata (string name)
    {
        var client = new Snapd.Client ();
        try {
            string suggested_currency;
            var snaps = yield client.find_async (Snapd.FindFlags.MATCH_NAME, name, null, out suggested_currency);
            if (snaps.length == 0)
                return;
            store_snap = snaps[0];
            changed ();
        }
        catch (Error e) {
            warning ("Failed to load store information on %s: %s", name, e.message);
        }
    }
}
