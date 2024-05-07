# discord-css

Some CSS changes to Discord

> **Warning**
> CSS Nesting is used, which requires Chromium >= 112 provided by Electron >= 24

> **Note**
> This is meant for use with an electron web client and consequently uses some webkit-specific selectors!

## Primary Objectives

1. Remove backgrounds to allow transparency (needs electron transparency enabled)
2. Change Discord's branding color

## Installation

🤷 depends on your client and its ability to inject stylesheets

[style.css](style.css) is the entrypoint, it will load all of the stylesheets in `css`
