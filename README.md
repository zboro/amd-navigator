# AMD navigator

This package adds single command for easy navigating in Javascript files (especially files using AMD syntax).

Click into your code, select "Go to module" command (ctrl + alt + X) and this package will try to navigate you to definition of selected function or module.

Currently it is possible to select these locations in code:

* **string with relative path** - .js file extension is assumed
* **string with AMD module identifier** (e.g. "app/myModule") - package name needs to be found in packages config.

	Packages need to be defined in Atom config file:
		"amd-navigator":
			packages:
				app: "src/app"

* **variable referencing AMD module** - e.g. any occurence of myModule variable in following example
		define([
			"app/myModule"
		], function(myModule) {
			//code
			myModule.myFunction();
		});

* **function or property of loaded AMD module** - e.g. "myFunction" from previous example. If function is selected, editor will try to scroll to that function. Function needs to be directly on module variable, "myModule.something.myFunction()" will not work.
* **any usage of function defined in the same file** - this won't open any file, only scroll the current one.

Searching for function declarations uses Atom's "Symbols View" package.

### Known issues

Soft wrap and code folding break opening modules when cursor is in string. (atom/atom#8685)
