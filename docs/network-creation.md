# Network Creation

The module must have constan:

* NAME <kbd>string</kbd> Network name

Function:
* setup(options) Called when the network is registered
* init(callback)
* request_idfa(callback) Optional
* is_supported() Return `boolean`
* is_initialized() Return `boolean`
* load_rewarded(callback)
* show_rewarded(callback)
* is_rewarded_loaded() Return `boolean`
* show_interstitial(callback)
* load_interstitial(callback)
* is_interstitial_loaded() Return `boolean`
* load_banner(callback)
* unload_banner(callback)
* is_banner_loaded() Return `boolean`
* show_banner(callback)
* hide_banner(callback)

Callback functions must be called **asynchronously** and the [response](../README.md/#response) parameter must be passed.

Example:

```lua
timer.delay(0, false, function()
    callback(response)
end)
```

## Helper

Helps create [responses](../README.md/#response). Require:

```lua
local helper = require("ads_wrapper.ads_networks.helper")
```

### `helper.success(message, data)`

Creates response `{result = events.SUCCESS, message = message, data = data}`

**Parameters**

- message <kbd>string</kbd> _optional_
- data <kbd>any</kbd> _optional_

### `helper.skipped(message)`

Creates response `{result = events.SUCCESS, code = events.C_SKIPPED, message = message}`

**Parameters**

- message <kbd>string</kbd> _optional_

### `helper.error(message, code)`

Creates response `{result = events.ERROR, code = code, message = message}`

**Parameters**

- message <kbd>string</kbd> _optional_
- code <kbd>hash</kbd> _optional_ Default `events.C_ERROR_UNKNOWN`

### `helper.abort(message)`

Used in internal processing.
Creates response `{result = events.ABORT, message = message}`

**Parameters**

- message <kbd>string</kbd> _optional_
