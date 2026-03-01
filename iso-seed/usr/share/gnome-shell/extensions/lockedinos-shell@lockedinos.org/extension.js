// LockedinOS GNOME Shell Extension
// Hides the top panel, dock, and Activities so the Electron dashboard
// is the only visible desktop interface.
//
// GNOME 45+ ESM module format.

import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class LockedinOSExtension extends Extension {
    enable() {
        // ── Hide the top panel ──
        Main.panel.hide();

        // ── Disable the hot corners ──
        this._origHotCorners = Main.layoutManager.hotCorners.slice();
        Main.layoutManager.hotCorners.forEach(corner => {
            if (corner) {
                corner._toggleOverview = () => {};
                corner._pressureBarrier?.destroy();
            }
        });

        // ── Hide the Activities button (belt-and-suspenders) ──
        if (Main.panel.statusArea.activities) {
            Main.panel.statusArea.activities.hide();
        }

        // ── Prevent the Overview from showing on startup ──
        if (Main.layoutManager._startingUp) {
            Main.layoutManager._startingUp = false;
        }
    }

    disable() {
        // Restore everything when extension is disabled
        Main.panel.show();

        if (Main.panel.statusArea.activities) {
            Main.panel.statusArea.activities.show();
        }
    }
}
