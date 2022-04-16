# Ads Wrapper for Defold

Ads Wrapper allows:

* Use the same interface for working with different advertising services.
* Advertising mediation - allows you to show ads from different sources.

Supported services: 

* [Admob](#admob)
* [Unity Ads](#unity-ads)
* [Poki](#poki)
* [Yandex](#yandex)
* [Vk Bridge](#vk-bridge)

Setting up [admob and unity ads](#admob-and-unity-ads) at the same time.

## Installation

You can use it in your own project by adding this project as a [Defold library dependency](http://www.defold.com/manuals/libraries/). Open your `game.project` file and in the dependencies field add **a link to the ZIP file of a [specific release](https://github.com/potatojam/defold-ads-wrapper/tags).**

## Initialization

First you need to make a require for `ads_wrapper.ads_wrapper` and `ads_wrapper.events`.

```lua
local ads_wrapper = require("ads_wrapper.ads_wrapper")
local events = require("ads_wrapper.events")
```

Next, you need to register the networks. More details about networks can be found [here](#networks).

```lua
-- Getting our module with networks
local test = require("ads_wrapper.ads_networks.test")
-- Register the first network
local test_1_id = ads_wrapper.register_network(test.network1, {param = "test_param 1"})
-- Register the second network
local test_2_id = ads_wrapper.register_network(test.network2, {param = "test_param 2"})
```

Next, you need to configure the mediators you need. 
There are two types: Video and Banner.
Video mediator refers to the functions associated with interstitials and rewarded videos.
Banner mediator refers to the functions associated with banners.
You need to set up only the mediator that you need. For example, Poki does not support banners.

```lua
-- Setup video mediator
ads_wrapper.setup_video({{id = test_2_id, count = 2}, {id = test_1_id, count = 2}}, 4)
-- Setup banner mediator
ads_wrapper.setup_banner({{id = test_1_id, count = 1}})
```

You can read more about mediators [here](#mediators).

Next, you need to initialize ads wrapper.

```lua
ads_wrapper.init(true, true, function(response)
    if response.result == events.SUCCESS then
        pprint("Ads wrapper is initialized", response)
    else
        pprint("Something bad happened", response)
    end
end)
```

In the first two parameters, you can specify the need to initialize the network.
First - `initilize_video`, Second - `initilize_banner`. This may take time depending on the service. 
Further, they can be initialized separately, if not done immediately.
When an advertisement is called, they will be initialized `automatically` if it has not been done before.

Almost all functions have a `callback` parameter.
`callback` - function which takes one `response` parameter.

## Response

The `response` can be of two types: `success` and `error`.

Response is a table:

* result <kbd>hash</kbd> _required_ May be `events.SUCCESS` or `events.ERROR`
* name <kbd>string</kbd> _optional_ Network name
* message <kbd>string</kbd> _optional_ Additional information. For example, consists info about error or it may report that the network has already been initialized when `init_video_networks` is called again.
* code <kbd>hash</kbd> _optional_ [Response code](#response-codes). Information that convient to track by code.
* responses <kbd>table</kbd> _optional_ Contains all responses if the function is called for multiple networks. This may be during initialization.
* was_open <kbd>table</kbd> _optional_ Some networks report whether ads was open when calling `show_interstitial` or `show_rewarded`.

Also, the response may contain additional information from a specific network.

Module `ads_wrapper.events` contains useful variables:

* `events.SUCCESS` <kbd>hash("SUCCESS")</kbd>
* `events.ERROR` <kbd>hash("ERROR")</kbd>

## Response Codes

The response table may have the code. All of them are contained in the `ads_wrapper.events` module, like `events.C_SKIPPED`. There are types of codes:

* `events.C_SKIPPED` <kbd>hash("C_SKIPPED")</kbd> - if the rewarded advertisement was skipped
* `events.C_ERROR_UNKNOWN` <kbd>hash("C_ERROR_UNKNOWN")</kbd> - an unknown error type is occured
* `events.C_ERROR_AD_BLOCK` <kbd>hash("C_ERROR_AD_BLOCK")</kbd> - an error is related to the adblock
* `events.C_ERROR_NO_CONNECTION` <kbd>hash("C_ERROR_NO_CONNECTION")</kbd> - no internet connection

## Mediators

Mediators are configured with two functions: `ads_wrapper.setup_video` and `ads_wrapper.setup_banner`.
The function sets the order which creates the queue.

Options:

* order <kbd>table</kbd> _required_ Ad display order. This is an array that contains objects like `{id = network_id, count = 2}`.
  * id <kbd>number</kbd> _required_ Id that you get when registering a network using `ads_wrapper.register_network`.
  * count <kbd>number</kbd> _optional_ how many times you need to show ads in a row in a queue. Default `1`
* repeat_cut <kbd>number</kbd> _optional_ specified if after the first cycle in queue it is necessary to cut off a part of the order. Default: the total number of all networks. Below are examples.

Examples:

1. Single network

    All other parameters are not needed for one network.

    ```lua
    ads_wrapper.setup_video({{id = test_id_1}})
    ```
    Queue: `test_1->test_1->test_1->test_1->test_1->`

2. Multiple networks with `repeat_cut` parameter

    ```lua
    ads_wrapper.setup_video({{id = test_id_1, count = 2}, {id = test_id_2, count = 2}, {id = test_id_1, count = 1}}, 3)
    ```

    Queue:
    - `1: test_1->test_1->test_2->test_2->test_1->`
    - `2: test_2->test_2->test_1->`
    - `3: test_2->test_2->test_1->`
    - And so on

    Part of the order is cut off after the first cycle.

3. Multiple networks without `repeat_cut` parameter

   `repeat_cut` automatically becomes `3`.

    ```lua
    ads_wrapper.setup_video({{id = test_id_1, count = 1}, {id = test_id_2, count = 2}})
    ```
    Queue:
    - `1: test_1->test_2->test_2->`
    - `2: test_1->test_2->test_2->`
    - `3: test_1->test_2->test_2->`
    - And so on

## Lua API

In many functions there is a queue of calls. Before calling `show_intertitial` `ads_wrapper` will check if the ad has been loaded, and if not, it will load it first. If there is an error somewhere, the queue will break.

### `ads_wrapper.register_network(network, params)`

Registers network. Returns id.

**Parameters**

- `network` <kbd>table</kbd> _required_ network module
- `params` <kbd>table</kbd> _required_ network options. They are different for every network. They can be found in the [networks](#networks) section.

**Return**

- id <kbd>number</kbd> Network id. It is needed to set up the mediator.

### `ads_wrapper.setup_video(order, repeat_count)`

Setups interstitial and reward mediator. More info [here](#mediators).

**Parameters**

- order <kbd>table</kbd> _required_ Ad display order. This is an array that contains objects like `{id = network_id, count = 2}`.
- repeat_cut <kbd>number</kbd> _optional_ specified if after the first cycle in queue it is necessary to cut off a part of the order. Default: the total number of all networks.

### `ads_wrapper.setup_banner(order, repeat_count)`

Setups banner mediator. More info [here](#mediators).

**Parameters**

- order <kbd>table</kbd> _required_ Ad display order. This is an array that contains objects like `{id = network_id, count = 2}`.
- repeat_cut <kbd>number</kbd> _optional_ specified if after the first cycle in queue it is necessary to cut off a part of the order. Default: the total number of all networks.

### `ads_wrapper.init(initilize_video, initilize_banner, callback)`

Initializes ads_wrapper. Callback consists `responses` field.

Queue: `check_connection->request_idfa->init`

**Parameters**

- initilize_video <kbd>boolean</kbd> _optional_  check if need to initialize video networks
- initilize_banner <kbd>boolean</kbd> _optional_ check if need to initialize banner networks
- callback <kbd>function</kbd> _optional_ callback with [response](#response).

### `ads_wrapper.init_video_networks(callback)`

Initialize video networks.

Queue: `check_connection->request_idfa->init`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.init_banner_networks(callback)`

Initialize banner networks.

Queue: `check_connection->request_idfa->init`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.load_rewarded(callback)`

Loads rewarded ads for next network.

Queue: `check_connection->request_idfa->init->load_rewarded`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.show_rewarded(callback)`

Shows rewarded ads for next network. Callback contain a special `code` field with [events.C_SKIPPED](#response-codes) if the user skipped the ad.

Queue: `check_connection->request_idfa->init->load_rewarded->show_rewarded`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response).

### `ads_wrapper.load_interstitial(callback)`

Loads interstitial ads for next network.

Queue: `check_connection->request_idfa->init->load_interstitial`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.show_interstitial(callback)`

Shows interstitial ads for next network.

Queue: `check_connection->request_idfa->init->load_interstitial->show_interstitial`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.load_banner(callback)`

Loads banner for for next network.

Queue: `check_connection->request_idfa->init->load_banner`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.show_banner(callback)`

Shows setup banner for next network. Hides the previous banner if it was displayed.

Queue: `check_connection->request_idfa->init->load_banner->show_banner`

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.hide_banner(callback)`

Hides setup banner for current network.

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.unload_banner(callback)`

Unloads banner for current networks.

**Parameters**

- callback <kbd>function</kbd> _optional_ callback with [response](#response)

### `ads_wrapper.is_banner_setup()`

Check if the banner mediator is set up

**Return**

- value <kbd>boolean</kbd>

### `ads_wrapper.is_video_setup()`

Check if the interstitial and rewarded video mediator is set up

**Return**

- value <kbd>boolean</kbd>

### `ads_wrapper.is_initialized()`

Check if ads wrapper is initiailzed

**Return**

- value <kbd>boolean</kbd>

### `ads_wrapper.is_internet_connected()`

Checks for internet connection

**Return**

- value <kbd>boolean</kbd>

### `ads_wrapper.clear_networks()`

Remove all registered networks

## Constants

Constants are used to set network parameters

* T_REWARDED <kbd>hash("T_REWARDED")</kbd>
* T_INTERSTITIAL <kbd>hash("T_INTERSTITIAL")</kbd>
* T_BANNER <kbd>hash("T_BANNER")</kbd>

## Platform

This module can be used in network settings.

```lua
local platform = require("ads_wrapper.platform")
```

Constants:
* PL_ANDROID <kbd>hash("PL_ANDROID")</kbd>
* PL_IOS <kbd>hash("PL_IOS")</kbd>
* PL_HTML5 <kbd>hash("PL_HTML5")</kbd>
* PL_OTHER <kbd>hash("PL_OTHER")</kbd>

### `platform.is_same(pl_value)`

**Parameters**

- pl_value <kbd>hash</kbd> _required_ One of the constants

Сheck if the platform is correct

**Return**

- value <kbd>boolean</kbd>

### `platform.get()`

Returns current hash platform

**Return**

- value <kbd>hash</kbd>

## Networks

You can use existing networks or create your own.

## Admob

The network uses [this](https://github.com/defold/extension-admob) extension.
In the `debug` mode will always be used test keys.
Verified version: **2.1.2**

You need to set:
* [ads_wrapper.T_INTERSTITIAL] <kbd>string</kbd> _required_ key for interstitial ads
* [ads_wrapper.T_REWARDED] <kbd>string</kbd> _required_ key for rewarded ads
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * id <kbd>string</kbd> _required_ key for banner
  * size <kbd>number</kbd> _optional_ banner size. Default `admob.SIZE_ADAPTIVE_BANNER`.
  * position <kbd>number</kbd> _optional_ banner position. Default `admob.POS_NONE`.

```lua
-- Need to add the extension: https://github.com/defold/extension-admob/archive/refs/tags/2.1.2.zip
local admob_module = require("ads_wrapper.ads_networks.admob")
local admob_net_id = ads_wrapper.register_network(admob_module, {
    [ads_wrapper.T_REWARDED] = "ca-app-pub-3940256099942544/5224354917",
    [ads_wrapper.T_INTERSTITIAL] = "ca-app-pub-3940256099942544/1033173712",
    [ads_wrapper.T_BANNER] = {
        id = "ca-app-pub-3940256099942544/6300978111",
        size = admob.SIZE_MEDIUM_RECTANGLE,
        position = admob.POS_BOTTOM_LEFT
    }
})
```

## Unity Ads

The network uses [this](https://github.com/AGulev/DefVideoAds) extension.
In the `debug` mode will always be used test keys.
Verified version: **4.1.2**

You need to set:
* ids <kbd>table</kbd> _required_ 
  * [platform.PL_ANDROID] <kbd>string</kbd> key for android
  * [platform.PL_IOS] <kbd>string</kbd> key for ios
* [ads_wrapper.T_INTERSTITIAL] <kbd>string</kbd> _required_ key for interstitial ads
* [ads_wrapper.T_REWARDED] <kbd>string</kbd> _required_ key for rewarded ads
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * id <kbd>string</kbd> _required_ key for banner
  * size <kbd>table</kbd> _optional_ banner size. Default `{width = 320, height = 50}`.
  * position <kbd>number</kbd> _optional_ banner position. Default `unityads.BANNER_POSITION_TOP_CENTER`.

```lua
-- Need to add the extension: https://github.com/AGulev/DefVideoAds/archive/refs/tags/4.1.2.zip
local unity = require("ads_wrapper.ads_networks.unity")
local platform = require("ads_wrapper.platform")
local unity_net_id = ads_wrapper.register_network(unity, {
    ids = {[platform.PL_ANDROID] = "1401815", [platform.PL_IOS] = "1425385"},
    [ads_wrapper.T_REWARDED] = "rewardedVideo",
    [ads_wrapper.T_INTERSTITIAL] = "video",
    [ads_wrapper.T_BANNER] = {id = "banner", size = {width = 720, height = 90}, position = unityads.BANNER_POSITION_BOTTOM_RIGHT}
})
```

## Poki

The network uses [this](https://github.com/AGulev/defold-poki-sdk) extension.
Poki does not support banners. Also, there are no additional options.
Verified version: **1.3.0**

```lua
-- Need to add the extension: https://github.com/AGulev/defold-poki-sdk/archive/refs/tags/1.3.0.zip
local poki = require("ads_wrapper.ads_networks.poki")
local poki_net_id = ads_wrapper.register_network(poki)
```

## Yandex

The network uses [this](https://github.com/indiesoftby/defold-yagames) extension.
Verified version: **0.7.4**

You need to set:
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * id <kbd>string</kbd> _required_ key for banner
  * size <kbd>table</kbd> _optional_ banner size. Default `{width = "100vw", height = "56vh"}`.
  * position <kbd>number</kbd> _optional_ banner position. Default `{x = "0px", y = "0px"}`.

Yandex must be configured in the module: `yandex.set_yandex_extention(yagames, sitelock)`

```lua
-- Need to add the extension: https://github.com/indiesoftby/defold-yagames/archive/refs/tags/0.7.4.zip
local yandex = require("ads_wrapper.ads_networks.yandex")
local yagames = require("yagames.yagames")
local sitelock = require("yagames.sitelock")
yandex.set_yandex_extention(yagames, sitelock)
local yandex_net_id = ads_wrapper.register_network(yandex, {
    [ads_wrapper.T_BANNER] = {
        id = "[your id here]",
        size = {width = "100vw", height = "56vh"},
        position = {x = "0px", y = "0px"}
    }
})
ads_wrapper.setup_video({{id = yandex_net_id, count = 1}}, 1)
ads_wrapper.setup_banner({{id = yandex_net_id, count = 1}}, 1)
```

## Vk Bridge

The network uses [this](https://github.com/potatojam/defold-vkbridge) extension.
Verified version: **1.0.1**

You need to set:
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * count <kbd>number</kbd> _optional_ banner count. Default `1`.
  * possition <kbd>string</kbd> _optional_ banner position. Default `top`.

Yandex must be configured in the module: `vk.set_vkbridge_extention(vkbridge)`

```lua
-- Need to add the extension: https://github.com/potatojam/defold-vkbridge/archive/refs/tags/1.0.1.zip
local vk = require("ads_wrapper.ads_networks.vk")
local vkbridge = require("vkbridge.vkbridge")
vk.set_vkbridge_extention(vkbridge)
local vk_net_id = ads_wrapper.register_network(vk, {
    [ads_wrapper.T_BANNER] = {count = 1, possition = "top"}
})
```

## Admob and Unity Ads

Example for two networks:

```lua
-- Need to add the extension: https://github.com/AGulev/DefVideoAds/archive/refs/tags/4.1.2.zip
local unity = require("ads_wrapper.ads_networks.unity")
local unity_net_id = ads_wrapper.register_network(unity, {
    ids = {[platform.PL_ANDROID] = "1401815", [platform.PL_IOS] = "1425385"},
    [ads_wrapper.T_REWARDED] = "rewardedVideo",
    [ads_wrapper.T_INTERSTITIAL] = "video",
    [ads_wrapper.T_BANNER] = {id = "banner", size = {width = 720, height = 90}, position = unityads.BANNER_POSITION_BOTTOM_RIGHT}
})
-- Need to add the extension: https://github.com/defold/extension-admob/archive/refs/tags/2.1.2.zip
local admob_module = require("ads_wrapper.ads_networks.admob")
local admob_net_id = ads_wrapper.register_network(admob_module, {
    [ads_wrapper.T_REWARDED] = "ca-app-pub-3940256099942544/5224354917",
    [ads_wrapper.T_INTERSTITIAL] = "ca-app-pub-3940256099942544/1033173712",
    [ads_wrapper.T_BANNER] = {
        id = "ca-app-pub-3940256099942544/6300978111",
        size = admob.SIZE_MEDIUM_RECTANGLE,
        position = admob.POS_BOTTOM_LEFT
    }
})
ads_wrapper.setup_video({{id = admob_net_id, count = 2}, {id = unity_net_id, count = 3}, {id = admob_net_id, count = 3}}, 6)
ads_wrapper.setup_banner({{id = admob_net_id, count = 2}, {id = unity_net_id, count = 1}}, 2)
ads_wrapper.init(true, true, function(response)
    pprint(response)
end)
```

## Test Networks

You can disable comments: 

```lua
test.is_debug = false
```

Example:

```lua
local test = require("ads_wrapper.ads_networks.test")
local test_1_id = ads_wrapper.register_network(test.network1, {param = "test_param 1"})
local test_2_id = ads_wrapper.register_network(test.network2, {param = "test_param 2"})
ads_wrapper.setup_video({{id = test_1_id, count = 1}, {id = test_2_id, count = 2}, {id = test_1_id, ount = 2}}, 4)
ads_wrapper.setup_banner({{id = test_1_id, count = 1}})
ads_wrapper.init(true, true, function(response)
    pprint(response)
end)
```

## Network Creation

You can create your own network.
It is best to look at already made networks.

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
* show_banner() Return [response](#response)
* hide_banner() Return [response](#response)

Callback functions must be called **asynchronously** and the [response](#response) parameter must be passed.

Example:

```lua
timer.delay(0, false, function()
    callback(response)
end)
```

## Helper

Helps create [responses](#response). Require:

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

## Debug mode

You can include output to the console of all operations that are done when calling functions with the queue.

```lua
local events = require("ads_wrapper.events")
local queue = require("ads_wrapper.queue")

queue.set_verbose_mode(events.V_ALL)
```

Constants:

* events.V_NONE <kbd>hash("V_NONE")</kbd> Output nothing. Default value.
* events.V_ERROR <kbd>hash("V_ERROR")</kbd> Show all errors
* events.V_SUCCESS <kbd>hash("V_SUCCESS")</kbd> Show all success responses
* events.V_ALL <kbd>hash("V_ALL")</kbd> Show all messages

## Credits

Made by [PotatoJam](https://github.com/potatojam).

For example used:

[Dirty Larry](https://github.com/andsve/dirtylarry)

[Druid](https://github.com/Insality/druid)

### License

MIT license.
