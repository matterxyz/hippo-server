# Optional DeviceCheck for HippoController

**Date:** 2026-07-27  
**Status:** Approved for implementation planning  
**Repo:** hippo-server

## Problem

`HippoController` (v1) registers `/object` routes without DeviceCheck middleware. Production `makeApplication` creates a `DeviceCheck` client but only passes it to `withAdditionalRoutes` (used by hippo-internal for v0). As a result, deployed `/v1` object routes are unprotected.

v0’s `AssetController` already accepts `DeviceCheck` and attaches `HummingbirdDeviceCheck` on its route group. HippoAPIv1 tests mount DeviceCheck at the router level, but the library and App wiring do not.

hippo-server is open source. Requiring DeviceCheck on `HippoController` would break existing library consumers.

## Goals

- Make it possible for all `HippoController` routes to run through DeviceCheck when a client is provided.
- Keep library API source-compatible: existing call sites with no DeviceCheck keep current behavior.
- Wire DeviceCheck in `makeApplication` so hippo-internal / App deployments protect `/v1` object routes.

## Non-goals

- Changing v0 `AssetController` / `HippoAPI` DeviceCheck wiring.
- Protecting `GET /` (health) or other non-`HippoController` routes.
- Changing DeviceCheck client creation or Apple API behavior.
- Forcing SPM consumers of `HippoAPIv1` to adopt DeviceCheck.

## Design

### Approach: optional `DeviceCheck` on `HippoController`

Add an optional parameter with a default of `nil`:

```swift
public init(
    metadataTable: String,
    assetsHostname: String,
    assetsBucket: String,
    deviceCheck: DeviceCheck? = nil
)
```

Store it on the controller. In `addRoutes(to:)`:

1. Build the `/object` route group as today.
2. If `deviceCheck` is non-nil, add `HummingbirdDeviceCheck(using: deviceCheck)` middleware on that group (same pattern as v0 `AssetController`).
3. Register get / create / fetch / delete handlers on the (possibly middleware-wrapped) group.

When `deviceCheck` is `nil`, behavior is identical to today: no DeviceCheck middleware.

### App wiring

In `makeApplication`, pass the existing `deviceCheck` instance into `HippoController`:

```swift
HippoController(
    metadataTable: metadataTable,
    assetsHostname: assetsHostname,
    assetsBucket: assetsBucket,
    deviceCheck: deviceCheck
).addRoutes(to: router.group("/v1"))
```

Impact:

| Consumer | Effect |
|---|---|
| SPM users constructing `HippoController` without `deviceCheck` | Unchanged (default `nil`) |
| `makeApplication` / hippo-internal / App binary | `/v1/object/*` requires DeviceCheck |
| v0 via `withAdditionalRoutes` | Unchanged |

### Tests

- Update `makeTestApp` in HippoAPIv1Tests to pass `deviceCheck` into `HippoController` instead of (or in addition to, then prefer instead of) adding `HummingbirdDeviceCheck` on the root router, so tests exercise the controller-owned middleware path.
- Keep coverage for missing device token → failure and valid token → route proceeds.
- Ensure a construction path with `deviceCheck: nil` still registers routes without requiring a token (documents opt-out / open-source default).

### Dependencies

`HippoAPIv1` already depends on `HummingbirdDeviceCheck`. No Package.swift dependency changes required.

## Error handling

Unchanged: `HummingbirdDeviceCheck` continues to reject missing/invalid tokens with the existing HTTP error mapping. Controllers do not re-implement DeviceCheck logic.

## Success criteria

1. Default `HippoController` init remains source-compatible and does not require DeviceCheck.
2. With a non-nil `deviceCheck`, every route registered by `HippoController` runs through DeviceCheck middleware.
3. `makeApplication` passes DeviceCheck so deployed `/v1` object routes are protected.
4. HippoAPIv1 tests verify both protected and unprotected construction paths as appropriate.
`)