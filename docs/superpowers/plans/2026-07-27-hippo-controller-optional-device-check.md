# Optional DeviceCheck for HippoController Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow `HippoController` to optionally attach DeviceCheck middleware on all of its routes (default off for open-source compatibility), and enable it from `makeApplication` so deployed `/v1` object routes are protected.

**Architecture:** Add `deviceCheck: DeviceCheck? = nil` to `HippoController`. When non-nil, attach `HummingbirdDeviceCheck` on the `/object` route group before registering handlers (same pattern as v0 `AssetController`). `makeApplication` passes its existing DeviceCheck client. Tests move middleware ownership into the controller.

**Tech Stack:** Swift, Hummingbird, DeviceCheck / HummingbirdDeviceCheck (existing targets in hippo-server)

**Spec:** `docs/superpowers/specs/2026-07-27-hippo-controller-optional-device-check-design.md`

## Global Constraints

- Library API must remain source-compatible: default `deviceCheck` is `nil` (no middleware).
- Do not change v0 AssetController / HippoAPI wiring.
- Do not protect `GET /` or non-HippoController routes.
- No Package.swift dependency changes (`HippoAPIv1` already depends on `HummingbirdDeviceCheck`).
- Prefer matching v0 middleware attachment style.

## File Structure

| File | Responsibility |
|------|----------------|
| `Sources/HippoAPIv1/HippoController.swift` | Optional DeviceCheck storage; conditional middleware on `/object` group |
| `Sources/App/Application+configure.swift` | Pass DeviceCheck into HippoController when registering `/v1` |
| `Tests/HippoAPIv1Tests/HippoControllerTests.swift` | `makeTestApp` passes DeviceCheck into controller; add nil-path coverage |

---

### Task 1: Optional DeviceCheck on HippoController + failing/updated tests

**Files:**
- Modify: `Sources/HippoAPIv1/HippoController.swift`
- Modify: `Tests/HippoAPIv1Tests/HippoControllerTests.swift`
- Test: `Tests/HippoAPIv1Tests/HippoControllerTests.swift`

**Interfaces:**
- Consumes: `DeviceCheck` protocol (`Sources/DeviceCheck/Utilities/DeviceCheck.swift`); `HummingbirdDeviceCheck` (`Sources/HummingbirdDeviceCheck/HummingbirdDeviceCheck.swift`)
- Produces: `HippoController.init(metadataTable:assetsHostname:assetsBucket:deviceCheck:)` with `deviceCheck: DeviceCheck? = nil`; `addRoutes(to:)` attaches middleware when non-nil

- [x] **Step 1: Update `makeTestApp` to pass DeviceCheck into HippoController and remove root-router middleware**

In `Tests/HippoAPIv1Tests/HippoControllerTests.swift`, replace `makeTestApp` with:

```swift
func makeTestApp(deviceCheck: (any DeviceCheck)?, hippo: Hippo) async throws -> some ApplicationProtocol {
  let router = Router()
  router.add(middleware: LogRequestsMiddleware(.info))

  HippoController(
    metadataTable: "metadata-table",
    assetsHostname: "test-hippo.example.com",
    assetsBucket: "assets",
    deviceCheck: deviceCheck
  ).addRoutes(to: router.group("/v1"))

  return Application(router: router)
}
```

Keep existing call sites that pass `MockDeviceCheckClient()` — they continue to test the protected path once the controller implements optional middleware.

- [x] **Step 2: Add a test that `deviceCheck: nil` does not require a Device-Token header**

Append to `HippoControllerTests`:

```swift
func testHippoController_withoutDeviceCheck_allowsRequestWithoutToken() async throws {
  let app = try await makeTestApp(
    deviceCheck: nil,
    hippo: Hippo(
      assetsHostName: "test-hippo.example.com",
      assetsBucketName: "assets",
      metadataTable: "metadata-table",
      objectStorage: MockObjectStorage()
    )
  )
  try await app.test(.router) { client in
    let response = try await client.execute(
      uri: "/v1/object?\(Parameter.clientReferenceOwner)=testReference&\(Parameter.clientReferenceID)=testID",
      method: .get,
      headers: [:],
      body: nil
    )
    // Without DeviceCheck middleware, missing token reaches the handler.
    // Current getObject uses empty owner/reference and throws .notFound on storage miss.
    XCTAssertEqual(response.status, .notFound)
  }
}
```

Note: `testHippoController_noDeviceToken` already expects `.badRequest` with empty headers when DeviceCheck is enabled — that remains the protected-path assertion.

- [x] **Step 3: Run the new/updated tests to confirm protected path still relies on missing controller API (or fails until Step 4)**

Run from `/Users/jaywilson/Developer/hippo-server`:

```bash
swift test --filter HippoControllerTests
```

Expected before implementation: compile error on `deviceCheck:` argument (unknown parameter), or if you implement init first without middleware, `testHippoController_noDeviceToken` fails (gets `.notFound` instead of `.badRequest`) and `testHippoController_withoutDeviceCheck_allowsRequestWithoutToken` may pass once init accepts nil.

Preferred TDD order: change tests first (Step 1–2), run (Step 3) → compile failure on `deviceCheck:` → implement controller (Step 4) → re-run.

- [x] **Step 4: Implement optional DeviceCheck on HippoController**

In `Sources/HippoAPIv1/HippoController.swift`:

1. Add `import HummingbirdDeviceCheck` (keep existing `import DeviceCheck`).
2. Add property and init parameter:

```swift
public struct HippoController: Sendable {
    let metadataTable: String
    let assetsHostname: String
    let assetsBucket: String
    let deviceCheck: (any DeviceCheck)?

    public init(
        metadataTable: String,
        assetsHostname: String,
        assetsBucket: String,
        deviceCheck: (any DeviceCheck)? = nil
    ) {
        self.metadataTable = metadataTable
        self.assetsHostname = assetsHostname
        self.assetsBucket = assetsBucket
        self.deviceCheck = deviceCheck
    }

    public func addRoutes(to group: RouterGroup<some RequestContext>) {
        var objectGroup = group.group("/object")
        if let deviceCheck {
            objectGroup = objectGroup.add(middleware: HummingbirdDeviceCheck(using: deviceCheck))
        }
        objectGroup.get(use: self.getObject)
            .post(use: self.createObject)
            .get("/{path}", use: self.fetchObject)
            .delete("/{path}", use: self.deleteObject)
    }
    // ... existing handlers unchanged ...
}
```

If `objectGroup = objectGroup.add(...)` fails to type-check (Hummingbird `add` return type), use an equivalent chain that matches `AssetController`:

```swift
public func addRoutes(to group: RouterGroup<some RequestContext>) {
    let objectGroup = group.group("/object")
    if let deviceCheck {
        objectGroup
            .add(middleware: HummingbirdDeviceCheck(using: deviceCheck))
            .get(use: self.getObject)
            .post(use: self.createObject)
            .get("/{path}", use: self.fetchObject)
            .delete("/{path}", use: self.deleteObject)
    } else {
        objectGroup
            .get(use: self.getObject)
            .post(use: self.createObject)
            .get("/{path}", use: self.fetchObject)
            .delete("/{path}", use: self.deleteObject)
    }
}
```

Prefer the non-duplicated `var` form if it compiles; otherwise use the if/else form.

- [x] **Step 5: Re-run HippoControllerTests**

```bash
swift test --filter HippoControllerTests
```

Expected: all HippoControllerTests PASS, including:
- `testHippoController_noDeviceToken` → `.badRequest`
- `testHippoController_withoutDeviceCheck_allowsRequestWithoutToken` → `.notFound`
- existing token-bearing tests still pass with `MockDeviceCheckClient()`

- [ ] **Step 6: Commit** (only if the user asked for a commit)

```bash
cd /Users/jaywilson/Developer/hippo-server
git add Sources/HippoAPIv1/HippoController.swift Tests/HippoAPIv1Tests/HippoControllerTests.swift
git commit -m "$(cat <<'EOF'
feat: optional DeviceCheck middleware on HippoController

Allow open-source consumers to keep unprotected routes by default while
enabling DeviceCheck when a client is provided.
EOF
)"
```

---

### Task 2: Wire DeviceCheck in makeApplication

**Files:**
- Modify: `Sources/App/Application+configure.swift` (HippoController construction ~lines 149–153)
- Test: `Tests/HippoAPIv1Tests/HippoControllerTests.swift` (already covers controller behavior); AppTests remain smoke-level

**Interfaces:**
- Consumes: `HippoController.init(..., deviceCheck:)` from Task 1; `deviceCheck` already created in `makeApplication`
- Produces: production `/v1` object routes protected via controller middleware

- [x] **Step 1: Pass `deviceCheck` into HippoController in `makeApplication`**

Replace the HippoController construction in `Sources/App/Application+configure.swift` with:

```swift
HippoController(
    metadataTable: metadataTable,
    assetsHostname: assetsHostname,
    assetsBucket: assetsBucket,
    deviceCheck: deviceCheck
).addRoutes(to: router.group("/v1"))
```

Leave `withAdditionalRoutes(router, hippo, deviceCheck)` unchanged.

- [x] **Step 2: Build App target / run a broader test filter**

```bash
swift test --filter 'HippoControllerTests|AppTests|HBDeviceCheckTests'
```

Expected: PASS (AppTests still pass with `testDeviceCheckClient`; HBDeviceCheckTests unchanged).

- [ ] **Step 3: Commit** (only if the user asked for a commit)

```bash
cd /Users/jaywilson/Developer/hippo-server
git add Sources/App/Application+configure.swift
git commit -m "$(cat <<'EOF'
feat: enable DeviceCheck for v1 routes in makeApplication

Pass the app DeviceCheck client into HippoController so deployed
/v1 object routes require a device token.
EOF
)"
```

---

### Task 3: Spec + plan docs in repo (optional housekeeping)

**Files:**
- Already created: `docs/superpowers/specs/2026-07-27-hippo-controller-optional-device-check-design.md`
- Already created: `docs/superpowers/plans/2026-07-27-hippo-controller-optional-device-check.md`

- [ ] **Step 1: Commit docs if the user wants them in git**

```bash
cd /Users/jaywilson/Developer/hippo-server
git add docs/superpowers/specs/2026-07-27-hippo-controller-optional-device-check-design.md \
        docs/superpowers/plans/2026-07-27-hippo-controller-optional-device-check.md
git commit -m "$(cat <<'EOF'
docs: add optional DeviceCheck for HippoController spec and plan
EOF
)"
```

---

## Spec coverage (self-review)

| Spec requirement | Task |
|------------------|------|
| Optional `deviceCheck: DeviceCheck? = nil` on HippoController | Task 1 |
| Middleware on route group when non-nil | Task 1 |
| `makeApplication` passes deviceCheck | Task 2 |
| Source-compatible default for SPM consumers | Task 1 default `nil` |
| Tests: protected + unprotected paths | Task 1 |
| No Package.swift / v0 / GET / changes | Global constraints; not in tasks |

No placeholders. Init signature consistent across tasks: `deviceCheck: (any DeviceCheck)? = nil`.
