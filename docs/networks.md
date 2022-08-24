# Networks

* [Test](#test-networks)
* [Admob](#admob)
* [Unity Ads](#unity-ads)
* [Poki](#poki)
* [Yandex](#yandex)
* [Vk Bridge](#vk-bridge)
* [Applovin Max](#applovin-max)
* [Admob and Unity Ads](#admob-and-unity-ads)

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
Verified version: **4.2.2**

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
Verified version: **1.0.2**

You need to set:
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * count <kbd>number</kbd> _optional_ banner count. Default `1`.
  * possition <kbd>string</kbd> _optional_ banner position. Default `top`.

Yandex must be configured in the module: `vk.set_vkbridge_extention(vkbridge)`

```lua
-- Need to add the extension: https://github.com/potatojam/defold-vkbridge/archive/refs/tags/1.0.2.zip
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
-- Need to add the extension: https://github.com/AGulev/DefVideoAds/archive/refs/tags/4.2.2.zip
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

## Applovin Max

> &#x26a0;&#xfe0f; The current version only supports Android


The network uses [this](https://github.com/alexeyfeskov/defold-maxsdk) extension.
Verified version: **11.4.4**

You need to set:
* [ads_wrapper.T_INTERSTITIAL] <kbd>string</kbd> _required_ key for interstitial ads
* [ads_wrapper.T_REWARDED] <kbd>string</kbd> _required_ key for rewarded ads
* [ads_wrapper.T_BANNER] <kbd>table</kbd> _optional_ banner options
  * id <kbd>string</kbd> _required_ key for banner
  * mrec_id <kbd>string</kbd> _required_ key for MREC banner
  * size <kbd>string</kbd> _optional_ banner size. Default `applovin_max.SIZE_BANNER`.
  * position <kbd>string</kbd> _optional_ banner position. Default `applovin_max.POS_NONE`.
* LDU <kbd>table</kbd> _optional_ LDU options. Use <kbd>maxsdk.set_fb_data_processing_options(LDU.name, LDU.country, LDU.state)</kbd>. If LDU is not set then use `nil` as parameter.
  * name <kbd>string</kbd> _optional_ Default `"LDU"`
  * country <kbd>number</kbd> _optional_ Defaul `0`
  * state <kbd>number</kbd> _optional_ Defaul `0`
* has_user_consent <kbd>boolean</kbd> _optional_ Use <kbd>maxsdk.set_has_user_consent(has_user_consent)</kbd>
* is_age_restricted_user <kbd>boolean</kbd> _optional_ Use <kbd>maxsdk.set_is_age_restricted_user(is_age_restricted_user)</kbd>
* do_not_sell <kbd>boolean</kbd> _optional_ Use <kbd>maxsdk.set_do_not_sell(do_not_sell)</kbd>
* muted <kbd>boolean</kbd> _optional_ Use <kbd>maxsdk.set_muted(muted)</kbd>
* verbose_logging <kbd>boolean</kbd> _optional_ Use <kbd>maxsdk.set_verbose_logging(verbose_logging)</kbd>

```lua
-- Need to add the extension: https://github.com/alexeyfeskov/defold-maxsdk/archive/refs/tags/11.4.4.zip
        local applovin_max = require("ads_wrapper.ads_networks.applovin_max")
        local applovin_max_net_id = ads_wrapper.register_network(applovin_max, {
            [ads_wrapper.T_REWARDED] = "YOUR_RE_AD_UNIT",
            [ads_wrapper.T_INTERSTITIAL] = "YOUR_IN_AD_UNIT",
            [ads_wrapper.T_BANNER] = {
                id = "YOUR_BA_AD_UNIT",
                mrec_id = "YOUR_MREC_AD_UNIT",
                size = applovin_max.POS_BOTTOM_CENTER,
                position = applovin_max.SIZE_BANNER
            },
            LDU = {
                name = "LDU",
                country = 1,
                state = 0
            },
            has_user_consent = true,
            is_age_restricted_user = false,
            do_not_sell = false,
            muted = false,
            verbose_logging = true
        })

        ads_wrapper.setup_video({{id = applovin_max_net_id, count = 1}}, 1)
        ads_wrapper.setup_banner({{id = applovin_max_net_id, count = 1}}, 1)
```