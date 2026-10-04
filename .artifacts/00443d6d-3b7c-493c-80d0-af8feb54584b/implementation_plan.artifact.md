# Implementation Plan - Update Favicons and Web Manifest

This plan outlines the steps to replace the current favicon and web manifest setup with the new assets provided in `web/icons/favicon-package/`.

## User Review Required

> [!IMPORTANT]
> I will replace the existing `manifest.json` with the new `site.webmanifest` (renamed to `manifest.json` for Flutter consistency or kept as `site.webmanifest` as per your snippet). I will also update the app name and description in the new manifest to match your project ("Keuangan Pribadi").

## Proposed Changes

### [Web Assets]

#### [MODIFY] [index.html](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/index.html)
- Remove legacy favicon and apple-touch-icon links.
- Insert the new links and meta tags provided.
- Update the manifest link.

#### [NEW] [favicon.ico](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/favicon.ico)
#### [NEW] [favicon.svg](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/favicon.svg)
#### [NEW] [favicon-96x96.png](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/favicon-96x96.png)
#### [NEW] [apple-touch-icon.png](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/apple-touch-icon.png)
#### [NEW] [icon-192.png](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/icon-192.png)
#### [NEW] [icon-512.png](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/icon-512.png)
#### [NEW] [site.webmanifest](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/site.webmanifest)

#### [DELETE] [manifest.json](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/web/manifest.json)
- Redundant once `site.webmanifest` is in place.

## Execution Steps

1.  **Copy Assets**: Use shell commands to copy the binary files from the package directory to the `web/` root.
2.  **Update Manifest**: Edit `site.webmanifest` to set the correct `name`, `short_name`, and `description`.
3.  **Update HTML**: Apply the code snippet to `index.html`.

## Verification Plan

### Manual Verification
- Check `index.html` to ensure the new tags are correctly placed and old ones removed.
- Verify `site.webmanifest` contains the correct app metadata.
- Confirm all new icon files exist in the `web/` directory.
