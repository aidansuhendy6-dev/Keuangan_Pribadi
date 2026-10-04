# Favicon Update Implementation Plan

This plan details the steps to update the web application's favicon using the new icons provided in `web/icons/favicon baru`.

## User Review Required

> [!IMPORTANT]
> I will move the icon files from the `web/icons/favicon baru` directory to the `web` root directory to match the paths provided in your HTML code. This will overwrite any existing `manifest.json` and `favicon.png` in the `web` folder.

## Proposed Changes

### Web Icons

- Move all 27 files from `web/icons/favicon baru/` to the `web/` directory.
- This includes apple icons, android icons, ms-icons, and favicons of various sizes.

### [MODIFY] [index.html](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/web/index.html)

- Remove existing iOS meta tags and favicon links.
- Add the new set of links and meta tags provided by the user, cleaned up for correct syntax.

### [MODIFY] [manifest.json](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/web/manifest.json)

- Update the `icons` array in `manifest.json` to reflect the new icons. I will merge the new icon definitions into the existing manifest to preserve your app's name and other settings.

## Verification Plan

### Manual Verification
- Verify that the files are present in the `web/` directory.
- Verify that `index.html` contains the updated links.
- The user can verify by running the Flutter web app and checking the browser tab and dev tools for icon loading.
