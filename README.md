# AMD navigator

Provides useful commands for navigating through AMD modules.

## Go to module

This command opens module referenced by code at cursor's current position.

Examples of currently supported positions are highlighted below

<pre>
    define([
        "<b>myApp/myModule</b>",
        "<b>./relativeModule</b>",
        "<b>./relativeModule2.js</b>"
    ], function(<b>myModule</b>, <b>relativeModule</b>, <b>relativeModule2</b>) {

        <b>relativeModule2</b>.<b>someFunction</b>();

    });
</pre>

### Known issues

Soft wrap and code folding break opening modules when cursor is in string.
